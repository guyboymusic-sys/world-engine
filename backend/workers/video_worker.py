"""Video generation worker (ModelScope text-to-video)."""
import uuid
import torch
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from backend.core.config import get_settings
from backend.models.models import GenerationJob, JobStatus
from backend.core.celery_app import celery_app

settings = get_settings()

# Sync engine for Celery workers (workers run synchronously)
_engine = None
_Session = None


def _get_session_factory():
    global _engine, _Session
    if _Session is None:
        _engine = create_engine(settings.database_sync_url)
        _Session = sessionmaker(bind=_engine)
    return _Session

OUTPUT_DIR = Path("/outputs/video")

_pipeline = None


def _get_pipeline():
    global _pipeline
    if _pipeline is None:
        from diffusers import DiffusionPipeline

        _pipeline = DiffusionPipeline.from_pretrained(
            settings.video_model_id,
            torch_dtype=torch.float16,
            cache_dir=settings.models_dir,
        )

        if torch.cuda.is_available():
            if hasattr(_pipeline, "enable_model_cpu_offload"):
                _pipeline.enable_model_cpu_offload()
            else:
                _pipeline = _pipeline.to("cuda")
        else:
            _pipeline = _pipeline.to("cpu")

        if hasattr(_pipeline, "enable_vae_slicing"):
            _pipeline.enable_vae_slicing()
        if hasattr(_pipeline, "enable_vae_tiling"):
            _pipeline.enable_vae_tiling()
    return _pipeline


@celery_app.task(
    name="backend.workers.video_worker.generate_video_task",
    bind=True,
    queue="video",
)
def generate_video_task(
    self,
    job_id: str,
    prompt: str,
    duration_seconds: int = 5,
    width: int = 1280,
    height: int = 720,
    fps: int = 24,
):
    with _get_session_factory()() as db:
        job = db.get(GenerationJob, uuid.UUID(job_id))
        job.status = JobStatus.started
        job.celery_task_id = self.request.id
        db.commit()

    try:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        pipe = _get_pipeline()
        num_frames = duration_seconds * fps

        output = pipe(
            prompt=prompt,
            num_frames=num_frames,
            height=height,
            width=width,
            num_inference_steps=50,
            guidance_scale=7.5,
        )

        frames = output.frames[0]

        import imageio
        out_path = OUTPUT_DIR / f"{job_id}.mp4"
        imageio.mimwrite(str(out_path), frames, fps=fps, quality=8)

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
