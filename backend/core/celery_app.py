"""Celery application instance."""
from celery import Celery
from celery.schedules import crontab
from backend.core.config import get_settings

settings = get_settings()

celery_app = Celery(
    "world_engine",
    broker=settings.redis_url,
    backend=settings.redis_url,
    include=[
        "backend.workers.video_worker",
        "backend.workers.audio_worker",
        "backend.workers.tts_worker",
        "backend.workers.llm_worker",
        "backend.workers.composite_worker",
        "backend.workers.chat_worker",
        "backend.workers.idle_worker",
    ],
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
    # Suppress Celery 6.0 deprecation warning; keep retry behaviour on startup.
    broker_connection_retry_on_startup=True,
    # Periodic tasks (requires `celery beat`)
    beat_schedule={
        # Poll YouTube Live Chat every 15 seconds
        "poll-youtube-chat": {
            "task": "backend.workers.chat_worker.poll_youtube_chat",
            "schedule": 15.0,
            "options": {"queue": "chat"},
        },
        # Check idle every 30 seconds
        "check-idle": {
            "task": "backend.workers.idle_worker.check_idle",
            "schedule": 30.0,
            "options": {"queue": "idle"},
        },
    },
)
