#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ -f ".venv/bin/activate" ]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

if [ -f "backend/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source backend/.env
  set +a
fi

export PYTHONPATH="$ROOT_DIR:${PYTHONPATH:-}"

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

uvicorn backend.main:app --host 0.0.0.0 --port "${FASTAPI_PORT:-8000}" &
api_pid=$!
workers_pgid_file="$(mktemp /tmp/world-engine-workers-pgid.XXXXXX)"
setsid bash -c 'echo $$ > "$1"; exec bash "$2"' bash "$workers_pgid_file" "$ROOT_DIR/scripts/run_workers.sh" &
workers_pid=$!

for _ in $(seq 1 50); do
  if [ -s "$workers_pgid_file" ]; then
    break
  fi
  sleep 0.1
done
workers_pgid="$(cat "$workers_pgid_file" 2>/dev/null || true)"
rm -f "$workers_pgid_file"

cleanup() {
  kill "$api_pid" >/dev/null 2>&1 || true
  if [ -n "${workers_pgid:-}" ]; then
    kill -- "-$workers_pgid" >/dev/null 2>&1 || true
  fi
  kill "$workers_pid" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

wait "$api_pid" "$workers_pid"
