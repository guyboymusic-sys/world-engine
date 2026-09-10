# One-click Deployment

This repository now supports one-command startup for local CPU/GPU hosts.

## What was fixed

1. Alembic now runs with `DATABASE_SYNC_URL` (sync engine) to avoid async migration issues.
2. Workers no longer require manual `CELERY_BROKER_URL` / `CELERY_RESULT_BACKEND` exports.
3. All 5 workers are started by one script with unique node names.
4. `backend/.env.example` now includes optional Celery override variables.

## Prerequisites

- Python 3.11
- Docker + Docker Compose plugin
- PostgreSQL and Redis ports available (`5432`, `6379`)

## One command options

### 1) Full local deploy (installs deps + infra + migrations + API + 5 workers)

```bash
./deploy.sh
```

### 2) Docker services

```bash
docker compose up -d
```

### 3) Run API + all workers after environment is ready

```bash
bash scripts/run_all.sh
```

## Worker-only launcher

```bash
bash scripts/run_workers.sh
```

Starts:

- Video worker (`video` queue)
- Audio worker (`audio` queue)
- TTS worker (`tts` queue)
- LLM worker (`llm` queue)
- Composite worker (`composite` queue)
