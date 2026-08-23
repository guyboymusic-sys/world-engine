# Configuration Reference (`backend/.env`)

This document explains every runtime variable used by World Engine, whether it is required, where to get values, and safe defaults.

## Required vs Optional

| Variable | Required | Purpose | Example |
|---|---|---|---|
| `DATABASE_URL` | Yes | Async DB URL used by API | `******db:5432/worldengine` |
| `DATABASE_SYNC_URL` | Yes | Sync DB URL used by workers/alembic | `******db:5432/worldengine` |
| `REDIS_URL` | Yes | Celery broker/result backend | `redis://redis:6379/0` |
| `SECRET_KEY` | Yes | Signing key for auth tokens/security | long random string |
| `MODELS_DIR` | Yes | Root directory for downloaded model weights | `/models` |
| `VIDEO_MODEL_ID` | Yes | Hugging Face model id for video generation | `damo-vilab/text-to-video-ms-1.7b` |
| `AUDIOLDM2_MODEL_ID` | Yes | Audio generation model id | `cvssp/audioldm2-large` |
| `MISTRAL_MODEL_ID` | Yes | LLM model id | `mistralai/Mistral-7B-Instruct-v0.3` |
| `TORTOISE_MODELS_DIR` | Yes | Local dir for tortoise model cache | `/models/tortoise` |
| `RTMP_SERVER` | Yes | RTMP endpoint used internally | `rtmp://nginx-rtmp:1935` |
| `STREAM_KEY` | Yes | Internal RTMP stream key | `live` |
| `YOUTUBE_STREAM_KEY` | Optional* | YouTube stream destination key | `abcd-efgh-...` |
| `YOUTUBE_API_KEY` | Optional | Needed for YouTube chat polling automation | `AIza...` |
| `YOUTUBE_CHANNEL_ID` | Optional | Used by YouTube integrations | channel id |
| `YOUTUBE_LIVE_CHAT_ID` | Optional | Needed only for direct live chat polling | live chat id |

\* `YOUTUBE_STREAM_KEY` is required only when pushing to YouTube directly. It can be empty for local RTMP testing.

---

## Generation Defaults

| Variable | Default | Description |
|---|---|---|
| `VIDEO_FPS` | `24` | Target video FPS |
| `VIDEO_WIDTH` | `1280` | Target output width |
| `VIDEO_HEIGHT` | `720` | Target output height |
| `VIDEO_DURATION_SECONDS` | `5` | Default generated video length |
| `AUDIO_DURATION_SECONDS` | `10` | Default generated audio length |
| `AUDIO_SAMPLE_RATE` | `16000` | Output sample rate for generated audio |

---

## Worker and API Runtime

| Variable | Default | Description |
|---|---|---|
| `VIDEO_WORKER_CONCURRENCY` | `1` | Video worker parallelism |
| `AUDIO_WORKER_CONCURRENCY` | `2` | Audio worker parallelism |
| `TTS_WORKER_CONCURRENCY` | `2` | TTS worker parallelism |
| `LLM_WORKER_CONCURRENCY` | `1` | LLM worker parallelism |
| `API_BASE_URL` | `http://api:8000/api/v1` | Internal worker -> API URL |

---

## Idle System

| Variable | Default | Description |
|---|---|---|
| `IDLE_TRIGGER_SECONDS` | `120` | Time without donation before auto-content generation |
| `IDLE_LEVEL` | `1` | Initial idle escalation level |

---

## Security Best Practices

1. **Always rotate `SECRET_KEY`** for production and keep it private.
2. Never commit `.env` to git.
3. Use least-privilege Google Cloud credentials for YouTube API usage.
4. If sharing logs, redact stream keys and API keys.
5. Prefer runtime secret injection (RunPod Secrets / Docker secrets) over plain-text files when possible.

---

## Performance Tuning

1. **VRAM constrained**: lower `VIDEO_DURATION_SECONDS`, keep `VIDEO_WORKER_CONCURRENCY=1`.
2. **CPU constrained**: lower `AUDIO_WORKER_CONCURRENCY` and `TTS_WORKER_CONCURRENCY`.
3. **Disk constrained**: keep `MODELS_DIR` on a high-capacity volume and monitor with `du -sh /models`.
4. **API latency spikes**: check Redis and Postgres container health before increasing worker counts.

---

## Where to find values

- **YouTube Stream Key**: YouTube Studio → Live Control Room → Stream Settings.
- **YouTube API Key**: Google Cloud Console → APIs & Services → Credentials (enable YouTube Data API v3).
- **YouTube Live Chat ID**: YouTube Data API `videos.list(part=liveStreamingDetails)` from live broadcast.
- **Model IDs**: Hugging Face model pages.

---

If you update model families or package versions, update both this file and `backend/.env.example` in the same change.
