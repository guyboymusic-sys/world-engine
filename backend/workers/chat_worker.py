"""YouTube Live Chat polling worker.

Polls the YouTube Data API v3 for new SuperChat / live-chat messages and
forwards donations to the donations endpoint so the LLM can react to them.

Start this worker alongside the other Celery workers:
    celery -A backend.core.celery_app:celery_app worker -Q chat --loglevel=info

The poller is a periodic Celery beat task (runs every ~15 seconds).
Add to your Celery beat schedule or start Celery beat alongside the worker.
"""
import httpx
import structlog
from backend.core.celery_app import celery_app
from backend.core.config import get_settings

settings = get_settings()
log = structlog.get_logger()

YOUTUBE_CHAT_URL = "https://www.googleapis.com/youtube/v3/liveChat/messages"
DONATIONS_URL = "http://localhost:8000/api/v1/donations"

# In-memory set of already-processed event IDs (survives worker restarts via Redis)
_PROCESSED_KEY = "world_engine:chat:processed_ids"


def _get_redis():
    import redis

    return redis.from_url(settings.redis_url)


@celery_app.task(
    name="backend.workers.chat_worker.poll_youtube_chat",
    queue="chat",
)
def poll_youtube_chat():
    """Fetch new YouTube Live Chat messages and process SuperChats as donations."""
    if not settings.youtube_api_key or not settings.youtube_live_chat_id:
        log.warning(
            "chat_poll_skipped",
            reason="YOUTUBE_API_KEY or YOUTUBE_LIVE_CHAT_ID not set",
        )
        return

    r = _get_redis()

    params = {
        "liveChatId": settings.youtube_live_chat_id,
        "part": "id,snippet,authorDetails",
        "maxResults": 200,
        "key": settings.youtube_api_key,
    }

    try:
        resp = httpx.get(YOUTUBE_CHAT_URL, params=params, timeout=10)
        resp.raise_for_status()
        data = resp.json()
    except Exception as exc:
        log.error("chat_poll_error", error=str(exc))
        return

    for item in data.get("items", []):
        event_id = item["id"]
        snippet = item.get("snippet", {})
        kind = snippet.get("type", "")

        # Only react to SuperChatEvents
        if kind != "superChatEvent":
            continue

        if r.sismember(_PROCESSED_KEY, event_id):
            continue  # already processed

        sc = snippet.get("superChatDetails", {})
        amount_usd = float(sc.get("amountMicros", 0)) / 1_000_000
        author = item.get("authorDetails", {}).get("displayName", "Anonymous")
        message = sc.get("userComment", "")

        payload = {
            "donor_name": author,
            "amount_usd": amount_usd,
            "message": message,
            "youtube_event_id": event_id,
        }

        try:
            post_resp = httpx.post(DONATIONS_URL, json=payload, timeout=10)
            if post_resp.status_code in (200, 201, 409):
                # 409 = already processed (idempotent), mark done
                r.sadd(_PROCESSED_KEY, event_id)
                # Keep the set from growing forever – cap at 10 000 entries
                r.execute_command("SRANDMEMBER", _PROCESSED_KEY)
                if r.scard(_PROCESSED_KEY) > 10_000:
                    r.spop(_PROCESSED_KEY, 1000)
            else:
                log.warning("donation_post_failed", status=post_resp.status_code, event_id=event_id)
        except Exception as exc:
            log.error("donation_post_error", error=str(exc), event_id=event_id)
