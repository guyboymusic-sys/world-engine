#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if command -v python3.11 >/dev/null 2>&1; then
  PYTHON_BIN="python3.11"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
else
  echo "Python 3.11 is required"
  exit 1
fi

if [ ! -d ".venv" ]; then
  "$PYTHON_BIN" -m venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r backend/requirements.txt

if [ ! -f "backend/.env" ]; then
  cp backend/.env.example backend/.env
fi

set -a
# shellcheck disable=SC1091
source backend/.env
set +a

export DATABASE_URL="${DEPLOY_DATABASE_URL:-${DATABASE_URL:-postgresql+asyncpg://worldengine:worldengine@localhost:5432/worldengine}}"
export DATABASE_SYNC_URL="${DEPLOY_DATABASE_SYNC_URL:-${DATABASE_SYNC_URL:-postgresql://worldengine:worldengine@localhost:5432/worldengine}}"
export REDIS_URL="${DEPLOY_REDIS_URL:-${REDIS_URL:-redis://localhost:6379/0}}"
if [ -n "${DEPLOY_REDIS_URL:-}" ]; then
  export CELERY_BROKER_URL="${DEPLOY_CELERY_BROKER_URL:-${CELERY_BROKER_URL:-$REDIS_URL}}"
  export CELERY_RESULT_BACKEND="${DEPLOY_CELERY_RESULT_BACKEND:-${CELERY_RESULT_BACKEND:-$REDIS_URL}}"
else
  export CELERY_BROKER_URL="${CELERY_BROKER_URL:-$REDIS_URL}"
  export CELERY_RESULT_BACKEND="${CELERY_RESULT_BACKEND:-$REDIS_URL}"
fi
export PYTHONPATH="$ROOT_DIR:${PYTHONPATH:-}"

if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "Installing Docker..."
  bash "$ROOT_DIR/scripts/install_docker.sh"
fi

docker compose version >/dev/null 2>&1 || {
  echo "Docker Compose is not available"
  exit 1
}

docker compose up -d db redis

db_ready=0
for _ in $(seq 1 30); do
  if docker compose exec -T db pg_isready -U worldengine >/dev/null 2>&1; then
    db_ready=1
    break
  fi
  sleep 2
done
if [ "$db_ready" -ne 1 ]; then
  echo "Database is not ready"
  exit 1
fi

redis_ready=0
for _ in $(seq 1 30); do
  if docker compose exec -T redis redis-cli ping >/dev/null 2>&1; then
    redis_ready=1
    break
  fi
  sleep 1
done
if [ "$redis_ready" -ne 1 ]; then
  echo "Redis is not ready"
  exit 1
fi

alembic upgrade head

bash "$ROOT_DIR/scripts/run_all.sh"
