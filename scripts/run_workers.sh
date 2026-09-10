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

if [ "${REDIS_URL:-}" = "redis://redis:6379/0" ]; then
  REDIS_URL="redis://localhost:6379/0"
fi

export REDIS_URL="${REDIS_URL:-redis://localhost:6379/0}"
export CELERY_BROKER_URL="${CELERY_BROKER_URL:-$REDIS_URL}"
export CELERY_RESULT_BACKEND="${CELERY_RESULT_BACKEND:-$REDIS_URL}"

VIDEO_WORKER_CONCURRENCY="${VIDEO_WORKER_CONCURRENCY:-1}"
AUDIO_WORKER_CONCURRENCY="${AUDIO_WORKER_CONCURRENCY:-1}"
TTS_WORKER_CONCURRENCY="${TTS_WORKER_CONCURRENCY:-1}"
LLM_WORKER_CONCURRENCY="${LLM_WORKER_CONCURRENCY:-1}"

pids=()
pgids=()

start_worker() {
  local name="$1"
  local queue="$2"
  local concurrency="$3"

  setsid celery -A backend.core.celery_app:celery_app worker \
    -Q "$queue" \
    --loglevel="${CELERY_LOGLEVEL:-info}" \
    --concurrency="$concurrency" \
    -n "${name}@%h" &

  pids+=("$!")
  pgids+=("$!")
}

cleanup() {
  for pgid in "${pgids[@]}"; do
    kill -- "-$pgid" >/dev/null 2>&1 || true
  done
  for pid in "${pids[@]}"; do
    kill "$pid" >/dev/null 2>&1 || true
  done
  wait || true
}

trap cleanup EXIT INT TERM

start_worker "video" "video" "$VIDEO_WORKER_CONCURRENCY"
start_worker "audio" "audio" "$AUDIO_WORKER_CONCURRENCY"
start_worker "tts" "tts" "$TTS_WORKER_CONCURRENCY"
start_worker "llm" "llm" "$LLM_WORKER_CONCURRENCY"
start_worker "composite" "composite" "${COMPOSITE_WORKER_CONCURRENCY:-1}"

wait
