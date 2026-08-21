# World Engine 🌍🎮

**AI-powered interactive streaming game with YouTube Live donations**

World Engine is a real-time, AI-driven game that runs live on YouTube. Donations from viewers trigger AI-generated events: narrated stories (Mistral 7B), ambient soundscapes (AudioLDM2), character voices (Tortoise TTS), and cinematic video clips (SkyReels V2), all composited and streamed back live via RTMP.

---

## Architecture

```
YouTube Live ──► Donation Webhook ──► FastAPI (REST API)
                                          │
                              ┌───────────┼───────────┐
                              ▼           ▼           ▼
                         Celery      Celery       Celery
                         LLM         Audio        Video
                         Worker      Worker       Worker
                           │           │             │
                      Mistral 7B  AudioLDM2    SkyReels V2
                           │           │             │
                           └───────────┴─────────────┘
                                       │
                              FFmpeg compositor
                                       │
                              nginx-RTMP ──► YouTube RTMP
```

**Services:**
| Service | Port | Purpose |
|---|---|---|
| FastAPI API | 8000 | REST API, job orchestration |
| PostgreSQL | 5432 | Persistent storage |
| Redis | 6379 | Celery broker & result backend |
| nginx-rtmp | 1935 / 8080 | RTMP ingest, HLS output |
| Celery Flower | 5555 | Worker monitoring UI |

---

## Prerequisites

- Python 3.11+
- Docker & Docker Compose v2
- NVIDIA GPU with CUDA 12.1+ (for AI workers)
- [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- ~80 GB disk space for models
- FFmpeg

---

## Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/guyboymusic-sys/world-engine.git
cd world-engine
cp backend/.env.example backend/.env
# Edit backend/.env with your secrets
```

### 2. Run setup (downloads all models)

```bash
bash scripts/setup.sh
```

This will:
1. Create a Python virtualenv and install all dependencies
2. Download all four AI models from Hugging Face (~70 GB total)
3. Start infrastructure containers (PostgreSQL, Redis, nginx-rtmp)
4. Run database migrations

### 3. Start the full stack

```bash
docker compose up -d
```

---

## Manual Installation

### Install Python dependencies

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r backend/requirements.txt
```

### Download AI models only

```bash
bash scripts/install_models.sh /path/to/models
```

**Models downloaded:**
| Model | Hugging Face ID | Size |
|---|---|---|
| SkyReels V2 (I2V 14B 720p) | `Skywork/SkyReels-V2-I2V-14B-720P` | ~28 GB |
| AudioLDM2 Large | `cvssp/audioldm2-large` | ~5 GB |
| Tortoise TTS | `jbetker/tortoise-tts-v2` (auto-downloaded) | ~8 GB |
| Mistral 7B Instruct v0.3 | `mistralai/Mistral-7B-Instruct-v0.3` | ~14 GB |

### Run database migrations

```bash
alembic upgrade head
```

### Start the API server

```bash
uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```

### Start Celery workers

```bash
# Video worker (GPU required)
celery -A backend.core.celery_app:celery_app worker -Q video --loglevel=info --concurrency=1

# Audio worker
celery -A backend.core.celery_app:celery_app worker -Q audio --loglevel=info --concurrency=2

# TTS worker
celery -A backend.core.celery_app:celery_app worker -Q tts --loglevel=info --concurrency=2

# LLM worker
celery -A backend.core.celery_app:celery_app worker -Q llm --loglevel=info --concurrency=1
```

---

## API Reference

Full interactive docs available at `http://localhost:8000/docs` (Swagger UI).

### Video Generation (SkyReels V2)

```http
POST /api/v1/video/generate
Content-Type: application/json

{
  "prompt": "a dragon flying over a volcano at sunset",
  "duration_seconds": 5,
  "width": 1280,
  "height": 720,
  "fps": 24
}
```

### Audio Generation (AudioLDM2)

```http
POST /api/v1/audio/generate
Content-Type: application/json

{
  "prompt": "epic orchestral battle music with drums",
  "duration_seconds": 10.0,
  "guidance_scale": 3.5,
  "num_inference_steps": 200
}
```

### Text-to-Speech (Tortoise TTS)

```http
POST /api/v1/tts/generate
Content-Type: application/json

{
  "text": "Brave adventurer, a storm approaches from the north!",
  "voice": "random"
}
```

### LLM Narrative (Mistral 7B)

```http
POST /api/v1/llm/generate
Content-Type: application/json

{
  "prompt": "Generate an in-game event triggered by a $50 donation",
  "max_new_tokens": 512
}
```

### Donations (YouTube SuperChat)

```http
POST /api/v1/donations
Content-Type: application/json

{
  "donor_name": "ViewerXYZ",
  "amount_usd": 20.00,
  "message": "Make it rain fire!",
  "youtube_event_id": "yt_superchat_abc123"
}
```

### Streaming

```http
POST /api/v1/stream/start    # Start RTMP push to YouTube
POST /api/v1/stream/stop     # Stop streaming
GET  /api/v1/stream/status   # Check streaming state
```

---

## Project Structure

```
world-engine/
├── backend/
│   ├── api/
│   │   ├── routes/          # FastAPI route handlers
│   │   │   ├── video.py     # SkyReels V2 endpoints
│   │   │   ├── audio.py     # AudioLDM2 endpoints
│   │   │   ├── tts.py       # Tortoise TTS endpoints
│   │   │   ├── llm.py       # Mistral 7B endpoints
│   │   │   ├── donations.py # YouTube donation handler
│   │   │   ├── stream.py    # RTMP stream control
│   │   │   └── health.py    # Health check
│   │   └── schemas.py       # Pydantic schemas
│   ├── core/
│   │   ├── config.py        # Pydantic settings
│   │   └── celery_app.py    # Celery instance
│   ├── db/
│   │   ├── database.py      # SQLAlchemy async engine
│   │   └── migrations/      # Alembic migrations
│   ├── models/
│   │   └── models.py        # ORM models
│   ├── workers/
│   │   ├── video_worker.py  # SkyReels V2 Celery task
│   │   ├── audio_worker.py  # AudioLDM2 Celery task
│   │   ├── tts_worker.py    # Tortoise TTS Celery task
│   │   └── llm_worker.py    # Mistral 7B Celery task
│   ├── tests/
│   ├── requirements.txt
│   └── .env.example
├── docker/
│   ├── Dockerfile.api       # API container
│   └── Dockerfile.worker    # GPU worker container
├── streaming/
│   └── nginx-rtmp.conf      # RTMP server config
├── scripts/
│   ├── install_models.sh    # Download all AI models
│   └── setup.sh             # Full environment setup
├── docker-compose.yml
├── alembic.ini
└── README.md
```

---

## Configuration

All settings are in `backend/.env` (copy from `backend/.env.example`):

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL async URL |
| `REDIS_URL` | Redis URL for Celery |
| `SECRET_KEY` | JWT signing key |
| `MODELS_DIR` | Path to AI model weights |
| `SKYREELS_MODEL_ID` | Hugging Face model ID for SkyReels |
| `AUDIOLDM2_MODEL_ID` | Hugging Face model ID for AudioLDM2 |
| `MISTRAL_MODEL_ID` | Hugging Face model ID for Mistral |
| `YOUTUBE_STREAM_KEY` | YouTube Live RTMP stream key |
| `YOUTUBE_API_KEY` | YouTube Data API v3 key |

---

## Running Tests

```bash
pip install pytest pytest-asyncio httpx
pytest
```

---

## License

MIT – see [LICENSE](LICENSE)
