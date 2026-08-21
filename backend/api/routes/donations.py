"""Donations endpoints – YouTube SuperChat integration."""
import uuid
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from backend.db.database import get_db
from backend.models.models import Donation, GenerationJob, JobStatus
from backend.workers.llm_worker import generate_llm_task
from backend.workers.idle_worker import reset_idle_on_donation
from backend.api.schemas import JobOut

router = APIRouter()


class DonationCreate(BaseModel):
    donor_name: str
    amount_usd: float
    message: str | None = None
    youtube_event_id: str | None = None


class DonationOut(BaseModel):
    id: uuid.UUID
    donor_name: str
    amount_usd: float
    message: str | None = None
    youtube_event_id: str | None = None
    job_id: uuid.UUID | None = None

    model_config = {"from_attributes": True}


@router.post("", response_model=DonationOut, status_code=201)
async def create_donation(payload: DonationCreate, db: AsyncSession = Depends(get_db)):
    # Deduplicate by youtube_event_id
    if payload.youtube_event_id:
        existing = await db.execute(
            select(Donation).where(Donation.youtube_event_id == payload.youtube_event_id)
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=409, detail="Donation already processed")

    # Trigger LLM to generate a narrative response to the donation
    prompt = (
        f"{payload.donor_name} donated ${payload.amount_usd:.2f}. "
        f"Message: '{payload.message or 'no message'}'. "
        "Generate an exciting in-game event based on this donation."
    )
    job = GenerationJob(job_type="llm", prompt=prompt, status=JobStatus.pending)
    db.add(job)
    await db.flush()

    task = generate_llm_task.delay(str(job.id), prompt, 256, 0.8, 0.9)
    job.celery_task_id = task.id

    donation = Donation(
        donor_name=payload.donor_name,
        amount_usd=payload.amount_usd,
        message=payload.message,
        youtube_event_id=payload.youtube_event_id,
        job_id=job.id,
    )
    db.add(donation)
    await db.commit()
    await db.refresh(donation)

    # Reset idle clock and level so the stream returns to calm state
    reset_idle_on_donation.delay()

    return donation


@router.get("", response_model=list[DonationOut])
async def list_donations(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Donation).order_by(Donation.created_at.desc()).limit(50))
    return result.scalars().all()
