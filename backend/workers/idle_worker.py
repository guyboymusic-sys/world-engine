"""Idle level system.

When no donation has arrived for IDLE_TRIGGER_SECONDS, this worker
automatically generates ambient content (LLM narrative + AudioLDM2 audio)
to keep the stream alive.  The "idle level" rises every trigger cycle,
making the ambient world progressively more dramatic.

Run as a Celery beat periodic task (see celery_app.py beat_schedule).
"""
import time
import httpx
import structlog
from backend.core.celery_app import celery_app
from backend.core.config import get_settings

settings = get_settings()
log = structlog.get_logger()

API_BASE = "http://localhost:8000/api/v1"

# Redis keys
_LAST_DONATION_KEY = "world_engine:idle:last_donation_ts"
_IDLE_LEVEL_KEY = "world_engine:idle:level"

# Prompts scale with idle level (1 = calm, 10 = apocalyptic)
_AMBIENT_PROMPTS = [
    "peaceful forest ambience with birds and gentle wind",           # 1
    "distant thunder rolling over calm plains",                      # 2
    "mysterious dungeon with dripping water and distant echoes",     # 3
    "ominous orchestral tension building in a haunted castle",       # 4
    "fierce storm with lightning and howling wind",                  # 5
    "epic battle drums and war horns approaching",                   # 6
    "volcanic eruption with crumbling earth and rumbling magma",     # 7
    "dragon roar echoing across burning ruins",                      # 8
    "apocalyptic choir with crashing waves and collapsing world",    # 9
    "divine cosmic explosion as reality tears apart",               # 10
]

_LLM_PROMPTS = [
    "Describe a quiet moment in the world. Villagers go about their day.",
    "A strange omen appears in the sky. Describe what the villagers see.",
    "Shadows gather at the edge of the forest. What lurks within?",
    "A dark force stirs. Ancient ruins begin to tremble.",
    "A fierce storm approaches the kingdom. The guards sound the alarm.",
    "Enemy forces have been spotted on the horizon. The king calls his generals.",
    "The volcano erupts! Lava flows toward the nearest village.",
    "A dragon descends from the mountains, its roar shaking the earth.",
    "The apocalypse begins. Dark portals open across the land.",
    "The world itself fractures as a god-like entity awakens from its slumber.",
]


def _get_redis():
    import redis

    return redis.from_url(settings.redis_url)


def _record_donation_time():
    """Call this whenever a real donation arrives to reset the idle clock."""
    r = _get_redis()
    r.set(_LAST_DONATION_KEY, str(time.time()))


def _get_idle_level(r) -> int:
    raw = r.get(_IDLE_LEVEL_KEY)
    return int(raw) if raw else 1


def _set_idle_level(r, level: int):
    r.set(_IDLE_LEVEL_KEY, str(min(max(level, 1), 10)))


@celery_app.task(
    name="backend.workers.idle_worker.check_idle",
    queue="idle",
)
def check_idle():
    """Periodic task: generate ambient content if stream has been idle too long."""
    r = _get_redis()

    last_ts_raw = r.get(_LAST_DONATION_KEY)
    last_ts = float(last_ts_raw) if last_ts_raw else 0.0
    seconds_idle = time.time() - last_ts

    if seconds_idle < settings.idle_trigger_seconds:
        log.debug("idle_check_ok", seconds_idle=round(seconds_idle, 1))
        return {"idle": False, "seconds_idle": seconds_idle}

    # Idle threshold exceeded – generate ambient content
    level = _get_idle_level(r)
    idx = min(level - 1, len(_AMBIENT_PROMPTS) - 1)
    ambient_prompt = _AMBIENT_PROMPTS[idx]
    narrative_prompt = _LLM_PROMPTS[idx]

    log.info("idle_trigger", level=level, seconds_idle=round(seconds_idle))

    try:
        # 1. Trigger LLM narrative
        httpx.post(
            f"{API_BASE}/llm/generate",
            json={"prompt": narrative_prompt, "max_new_tokens": 256},
            timeout=5,
        )

        # 2. Trigger ambient audio
        httpx.post(
            f"{API_BASE}/audio/generate",
            json={
                "prompt": ambient_prompt,
                "duration_seconds": settings.audio_duration_seconds,
            },
            timeout=5,
        )
    except Exception as exc:
        log.error("idle_trigger_error", error=str(exc))

    # Increase idle level (capped at 10)
    _set_idle_level(r, level + 1)

    # Reset the idle clock so we don't trigger again immediately
    r.set(_LAST_DONATION_KEY, str(time.time()))

    return {"idle": True, "level": level, "seconds_idle": seconds_idle}


@celery_app.task(
    name="backend.workers.idle_worker.reset_idle_on_donation",
    queue="idle",
)
def reset_idle_on_donation():
    """Call after a real donation to reset idle clock and drop level back to 1."""
    r = _get_redis()
    r.set(_LAST_DONATION_KEY, str(time.time()))
    _set_idle_level(r, 1)
    log.info("idle_reset")
