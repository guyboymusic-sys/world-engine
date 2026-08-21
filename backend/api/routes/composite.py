"""Compositing route – trigger audio+video merge into stream_input.mp4."""
import uuid
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from backend.db.database import get_db
from backend.models.models import GenerationJob, JobStatus
from backend.workers.composite_worker import composite_task
from backend.api.schemas import JobOut

router = APIRouter()


class CompositeRequest(BaseModel):
    video_path: str  # absolute path returned by video generation job
    audio_path: str  # absolute path returned by audio generation job


@router.post("/build", response_model=JobOut, status_code=202)
async def build_composite(req: CompositeRequest, db: AsyncSession = Depends(get_db)):
    """Merge video and audio into /outputs/stream_input.mp4.

    Call this after both a video generation job and an audio generation job
    have completed successfully.  Once the composite job finishes you can
    call POST /api/v1/stream/start to begin streaming.
    """
    job = GenerationJob(
        job_type="composite",
        prompt=f"video={req.video_path} audio={req.audio_path}",
        status=JobStatus.pending,
    )
    db.add(job)
    await db.commit()
    await db.refresh(job)

    task = composite_task.delay(str(job.id), req.video_path, req.audio_path)

    job.celery_task_id = task.id
    await db.commit()
    await db.refresh(job)
    return job


@router.get("/{job_id}", response_model=JobOut)
async def get_composite_job(job_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    job = await db.get(GenerationJob, job_id)
    if not job or job.job_type != "composite":
        raise HTTPException(status_code=404, detail="Job not found")
    return job
