#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "⚙️  World Engine - Configuration Phase"

rewrite_service_host() {
  local value="$1"
  local from_host="$2"
  local to_host="$3"

  printf '%s\n' "$value" | sed -E "s#(//|@)${from_host}([:/])#\1${to_host}\2#"
}

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

if [ -n "${DATABASE_URL:-}" ]; then
  DATABASE_URL="$(rewrite_service_host "$DATABASE_URL" "db" "localhost")"
fi
if [ -n "${DATABASE_SYNC_URL:-}" ]; then
  DATABASE_SYNC_URL="$(rewrite_service_host "$DATABASE_SYNC_URL" "db" "localhost")"
fi
if [ -n "${REDIS_URL:-}" ]; then
  REDIS_URL="$(rewrite_service_host "$REDIS_URL" "redis" "localhost")"
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
