# One-click Deployment

This repository now supports one-command startup for local CPU/GPU hosts.

## What was fixed

1. Alembic now runs with a sync URL for migrations (`DATABASE_SYNC_URL`, or a sync fallback derived from `DATABASE_URL`).
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

Optional local endpoint overrides:

```bash
DEPLOY_DATABASE_URL=******localhost:5432/worldengine \
DEPLOY_DATABASE_SYNC_URL=******localhost:5432/worldengine \
DEPLOY_REDIS_URL=redis://localhost:6379/0 \
./deploy.sh
```

You can also override Celery endpoints during deploy with:
`DEPLOY_CELERY_BROKER_URL` and `DEPLOY_CELERY_RESULT_BACKEND`.

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
