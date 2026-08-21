"""Text-to-speech endpoints (Tortoise TTS)."""
import uuid
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from backend.db.database import get_db
from backend.models.models import GenerationJob, JobStatus
from backend.workers.tts_worker import generate_tts_task
from backend.api.schemas import JobOut

router = APIRouter()


class TTSRequest(BaseModel):
    text: str
    voice: str = "random"
    num_autoregressive_samples: int = 4
    diffusion_iterations: int = 80


@router.post("/generate", response_model=JobOut, status_code=202)
async def generate_tts(req: TTSRequest, db: AsyncSession = Depends(get_db)):
    job = GenerationJob(
        job_type="tts",
        prompt=req.text,
        status=JobStatus.pending,
    )
    db.add(job)
    await db.commit()
    await db.refresh(job)

    task = generate_tts_task.delay(
        str(job.id),
        req.text,
        req.voice,
        req.num_autoregressive_samples,
        req.diffusion_iterations,
    )

    job.celery_task_id = task.id
    await db.commit()
    await db.refresh(job)
    return job


@router.get("/{job_id}", response_model=JobOut)
async def get_tts_job(job_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    job = await db.get(GenerationJob, job_id)
    if not job or job.job_type != "tts":
        raise HTTPException(status_code=404, detail="Job not found")
    return job
