"""Audio generation endpoints (AudioLDM2)."""
import uuid
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from backend.db.database import get_db
from backend.models.models import GenerationJob, JobStatus
from backend.workers.audio_worker import generate_audio_task
from backend.api.schemas import JobOut

router = APIRouter()


class AudioRequest(BaseModel):
    prompt: str
    duration_seconds: float = 10.0
    guidance_scale: float = 3.5
    num_inference_steps: int = 200


@router.post("/generate", response_model=JobOut, status_code=202)
async def generate_audio(req: AudioRequest, db: AsyncSession = Depends(get_db)):
    job = GenerationJob(
        job_type="audio",
        prompt=req.prompt,
        status=JobStatus.pending,
    )
    db.add(job)
    await db.commit()
    await db.refresh(job)

    task = generate_audio_task.delay(
        str(job.id),
        req.prompt,
        req.duration_seconds,
        req.guidance_scale,
        req.num_inference_steps,
    )

    job.celery_task_id = task.id
    await db.commit()
    await db.refresh(job)
    return job


@router.get("/{job_id}", response_model=JobOut)
async def get_audio_job(job_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    job = await db.get(GenerationJob, job_id)
    if not job or job.job_type != "audio":
        raise HTTPException(status_code=404, detail="Job not found")
    return job
