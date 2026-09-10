#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "⚙️  World Engine - Configuration Phase"

if [ ! -f ".venv/bin/activate" ]; then
  echo "Virtual environment is missing. Run bash scripts/install.sh first."
  exit 1
fi

# shellcheck disable=SC1091
source .venv/bin/activate

if [ ! -f "backend/.env" ]; then
  cp backend/.env.example backend/.env
fi

if [ -f "backend/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source backend/.env
  set +a
fi

export PYTHONPATH="$ROOT_DIR${PYTHONPATH:+:$PYTHONPATH}"

if [ "${DATABASE_URL:-}" = "******db:5432/worldengine" ]; then
  DATABASE_URL="******localhost:5432/worldengine"
fi
if [ "${DATABASE_SYNC_URL:-}" = "******db:5432/worldengine" ]; then
  DATABASE_SYNC_URL="******localhost:5432/worldengine"
fi
if [ "${REDIS_URL:-}" = "redis://redis:6379/0" ]; then
  REDIS_URL="redis://localhost:6379/0"
fi

export DATABASE_URL="${DATABASE_URL:-postgresql+asyncpg://worldengine:worldengine@localhost:5432/worldengine}"
export DATABASE_SYNC_URL="${DATABASE_SYNC_URL:-postgresql://worldengine:worldengine@localhost:5432/worldengine}"
export REDIS_URL="${REDIS_URL:-redis://localhost:6379/0}"
export CELERY_BROKER_URL="${CELERY_BROKER_URL:-$REDIS_URL}"
export CELERY_RESULT_BACKEND="${CELERY_RESULT_BACKEND:-$REDIS_URL}"

db_ready=0
for i in $(seq 1 30); do
  if docker compose exec -T db pg_isready -U worldengine >/dev/null 2>&1; then
    echo "✅ PostgreSQL ready"
    db_ready=1
    break
  fi
  echo "⏳ Waiting for PostgreSQL... ($i/30)"
  sleep 2
done
if [ "$db_ready" -ne 1 ]; then
  echo "PostgreSQL is not ready"
  exit 1
fi

redis_ready=0
for i in $(seq 1 30); do
  if docker compose exec -T redis redis-cli ping >/dev/null 2>&1; then
    echo "✅ Redis ready"
    redis_ready=1
    break
  fi
  echo "⏳ Waiting for Redis... ($i/30)"
  sleep 1
done
if [ "$redis_ready" -ne 1 ]; then
  echo "Redis is not ready"
  exit 1
fi

alembic upgrade head

echo "✅ Configuration complete!"
