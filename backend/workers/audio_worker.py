"""AudioLDM2 audio generation worker."""
import uuid
import torch
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import soundfile as sf

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

OUTPUT_DIR = Path("/outputs/audio")

_pipeline = None


def _get_pipeline():
    global _pipeline
    if _pipeline is None:
        from diffusers import AudioLDM2Pipeline

        _pipeline = AudioLDM2Pipeline.from_pretrained(
            settings.audioldm2_model_id,
            torch_dtype=torch.float16,
            cache_dir=settings.models_dir,
        )
        _pipeline = _pipeline.to("cuda" if torch.cuda.is_available() else "cpu")
    return _pipeline


@celery_app.task(name="backend.workers.audio_worker.generate_audio_task", bind=True, queue="audio")
def generate_audio_task(
    self,
    job_id: str,
    prompt: str,
    duration_seconds: float = 10.0,
    guidance_scale: float = 3.5,
    num_inference_steps: int = 200,
):
    with _get_session_factory()() as db:
        job = db.get(GenerationJob, uuid.UUID(job_id))
        job.status = JobStatus.started
        job.celery_task_id = self.request.id
        db.commit()

    try:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        pipe = _get_pipeline()
        output = pipe(
            prompt,
            audio_length_in_s=duration_seconds,
            guidance_scale=guidance_scale,
            num_inference_steps=num_inference_steps,
            negative_prompt="low quality, noisy",
        )

        audio = output.audios[0]
        out_path = OUTPUT_DIR / f"{job_id}.wav"
        sf.write(str(out_path), audio, settings.audio_sample_rate)

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
