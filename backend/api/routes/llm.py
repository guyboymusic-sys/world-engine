"""LLM endpoints (Mistral 7B)."""
import uuid
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from backend.db.database import get_db
from backend.models.models import GenerationJob, JobStatus
from backend.workers.llm_worker import generate_llm_task
from backend.api.schemas import JobOut

router = APIRouter()


class LLMRequest(BaseModel):
    prompt: str
    max_new_tokens: int = 512
    temperature: float = 0.7
    top_p: float = 0.9


@router.post("/generate", response_model=JobOut, status_code=202)
async def generate_llm(req: LLMRequest, db: AsyncSession = Depends(get_db)):
    job = GenerationJob(
        job_type="llm",
        prompt=req.prompt,
        status=JobStatus.pending,
    )
    db.add(job)
    await db.commit()
    await db.refresh(job)

    task = generate_llm_task.delay(
        str(job.id),
        req.prompt,
        req.max_new_tokens,
        req.temperature,
        req.top_p,
    )

    job.celery_task_id = task.id
    await db.commit()
    await db.refresh(job)
    return job


@router.get("/{job_id}", response_model=JobOut)
async def get_llm_job(job_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    job = await db.get(GenerationJob, job_id)
    if not job or job.job_type != "llm":
        raise HTTPException(status_code=404, detail="Job not found")
    return job
