"""Mistral 7B LLM worker."""
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

OUTPUT_DIR = Path("/outputs/llm")

_model = None
_tokenizer = None


def _get_model():
    global _model, _tokenizer
    if _model is None:
        from transformers import AutoTokenizer, AutoModelForCausalLM

        _tokenizer = AutoTokenizer.from_pretrained(
            settings.mistral_model_id,
            cache_dir=settings.models_dir,
        )
        _model = AutoModelForCausalLM.from_pretrained(
            settings.mistral_model_id,
            torch_dtype=torch.float16,
            device_map="auto",
            cache_dir=settings.models_dir,
        )
    return _model, _tokenizer


@celery_app.task(name="backend.workers.llm_worker.generate_llm_task", bind=True, queue="llm")
def generate_llm_task(
    self,
    job_id: str,
    prompt: str,
    max_new_tokens: int = 512,
    temperature: float = 0.7,
    top_p: float = 0.9,
):
    with _get_session_factory()() as db:
        job = db.get(GenerationJob, uuid.UUID(job_id))
        job.status = JobStatus.started
        job.celery_task_id = self.request.id
        db.commit()

    try:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        model, tokenizer = _get_model()

        messages = [
            {"role": "system", "content": "You are a creative AI game master for an interactive streaming game."},
            {"role": "user", "content": prompt},
        ]

        encoded = tokenizer.apply_chat_template(
            messages,
            return_tensors="pt",
            add_generation_prompt=True,
        ).to(model.device)

        with torch.no_grad():
            outputs = model.generate(
                encoded,
                max_new_tokens=max_new_tokens,
                temperature=temperature,
                top_p=top_p,
                do_sample=True,
                pad_token_id=tokenizer.eos_token_id,
            )

        response_ids = outputs[0][encoded.shape[-1]:]
        response_text = tokenizer.decode(response_ids, skip_special_tokens=True)

        out_path = OUTPUT_DIR / f"{job_id}.txt"
        out_path.write_text(response_text, encoding="utf-8")

        with _get_session_factory()() as db:
            job = db.get(GenerationJob, uuid.UUID(job_id))
            job.status = JobStatus.success
            job.result_path = str(out_path)
            db.commit()

        return response_text

    except Exception as exc:
        with _get_session_factory()() as db:
            job = db.get(GenerationJob, uuid.UUID(job_id))
            job.status = JobStatus.failure
            job.error_message = str(exc)
            db.commit()
        raise
