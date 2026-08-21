"""Video generation endpoints."""
import uuid
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from backend.db.database import get_db
from backend.models.models import GenerationJob, JobStatus
from backend.workers.video_worker import generate_video_task
from backend.api.schemas import JobOut

router = APIRouter()


class VideoRequest(BaseModel):
    prompt: str
    duration_seconds: int = 5
    width: int = 1280
    height: int = 720
    fps: int = 24


@router.post("/generate", response_model=JobOut, status_code=202)
async def generate_video(req: VideoRequest, db: AsyncSession = Depends(get_db)):
    job = GenerationJob(
        job_type="video",
        prompt=req.prompt,
        status=JobStatus.pending,
    )
    db.add(job)
    await db.commit()
    await db.refresh(job)

    task = generate_video_task.delay(
        str(job.id),
        req.prompt,
        req.duration_seconds,
        req.width,
        req.height,
        req.fps,
    )

    job.celery_task_id = task.id
    await db.commit()
    await db.refresh(job)
    return job


@router.get("/{job_id}", response_model=JobOut)
async def get_video_job(job_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    job = await db.get(GenerationJob, job_id)
    if not job or job.job_type != "video":
        raise HTTPException(status_code=404, detail="Job not found")
    return job
