"""Tortoise TTS worker."""
import uuid
import torch
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from backend.core.config import get_settings
from backend.models.models import GenerationJob, JobStatus
from backend.core.celery_app import celery_app

settings = get_settings()

_engine = None
_Session = None


def _get_session_factory():
    global _engine, _Session
    if _Session is None:
        _engine = create_engine(settings.database_sync_url)
        _Session = sessionmaker(bind=_engine)
    return _Session

OUTPUT_DIR = Path("/outputs/tts")

_tts = None


def _get_tts():
    global _tts
    if _tts is None:
        from tortoise.api import TextToSpeech  # type: ignore[import]

        _tts = TextToSpeech(models_dir=settings.tortoise_models_dir)
    return _tts


@celery_app.task(name="backend.workers.tts_worker.generate_tts_task", bind=True, queue="tts")
def generate_tts_task(
    self,
    job_id: str,
    text: str,
    voice: str = "random",
    num_autoregressive_samples: int = 4,
    diffusion_iterations: int = 80,
):
    with _get_session_factory()() as db:
        job = db.get(GenerationJob, uuid.UUID(job_id))
        job.status = JobStatus.started
        job.celery_task_id = self.request.id
        db.commit()

    try:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        import torchaudio
        from tortoise.utils.audio import load_voices  # type: ignore[import]

        tts = _get_tts()
        voice_samples, conditioning_latents = load_voices([voice])

        gen = tts.tts_with_preset(
            text,
            voice_samples=voice_samples,
            conditioning_latents=conditioning_latents,
            preset="fast",
            num_autoregressive_samples=num_autoregressive_samples,
            diffusion_iterations=diffusion_iterations,
        )

        out_path = OUTPUT_DIR / f"{job_id}.wav"
        torchaudio.save(str(out_path), gen.squeeze(0).cpu(), 24000)

        with _get_session_factory()() as db:
            job = db.get(GenerationJob, uuid.UUID(job_id))
            job.status = JobStatus.success
            job.result_path = str(out_path)
            db.commit()

        return str(out_path)

    except Exception as exc:
        with _get_session_factory()() as db:
            job = db.get(GenerationJob, uuid.UUID(job_id))
            job.status = JobStatus.failure
            job.error_message = str(exc)
            db.commit()
        raise
