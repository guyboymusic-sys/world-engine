"""Pydantic schemas shared across routes."""
import uuid
from datetime import datetime
from pydantic import BaseModel, Field
from backend.models.models import JobStatus


class JobOut(BaseModel):
    id: uuid.UUID
    job_type: str
    status: JobStatus
    prompt: str
    result_path: str | None = None
    error_message: str | None = None
    celery_task_id: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}
