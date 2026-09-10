#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "⚙️  World Engine - Configuration Phase"

load_env_file() {
  local env_file="$1"
  local line trimmed_line key value

  while IFS= read -r line || [ -n "$line" ]; do
    trimmed_line="$(trim_leading_whitespace "$line")"
    case "$trimmed_line" in
      ''|'#'*)
        continue
        ;;
    esac

    line="$trimmed_line"
    line="${line#export }"
    key="${line%%=*}"
    value="${line#*=}"
    key="$(trim_whitespace "$key")"
    value="$(trim_whitespace "$value")"

    case "$key" in
      [A-Za-z_][A-Za-z0-9_]*)
        ;;
      *)
        continue
        ;;
    esac

    value="${value%$'\r'}"

    printf -v "$key" '%s' "$value"
    export "$key"
  done < "$env_file"
}

trim_leading_whitespace() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  printf '%s' "$value"
}

trim_whitespace() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

normalize_url_value() {
  local value="$1"
  if [[ "$value" =~ ^\".*\"$ || "$value" =~ ^\'.*\'$ ]]; then
    printf '%s' "${value:1:${#value}-2}"
    return
  fi
  printf '%s' "$value"
}

rewrite_service_host() {
  python - "$1" "$2" "$3" <<'PY'
from urllib.parse import urlsplit, urlunsplit
import sys

value, from_host, to_host = sys.argv[1:4]
parts = urlsplit(value)
if not parts.scheme or not parts.netloc:
    print(value)
    raise SystemExit

if parts.hostname != from_host:
    print(value)
    raise SystemExit

userinfo = ""
if parts.username is not None:
    userinfo = parts.username
    if parts.password is not None:
        userinfo = f"{userinfo}:{parts.password}"
    userinfo = f"{userinfo}@"

host = to_host
if ":" in host and not host.startswith("["):
    host = f"[{host}]"

netloc = f"{userinfo}{host}"
if parts.port is not None:
    netloc = f"{netloc}:{parts.port}"

print(urlunsplit((parts.scheme, netloc, parts.path, parts.query, parts.fragment)))
PY
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
  load_env_file "backend/.env"
fi

export PYTHONPATH="$ROOT_DIR${PYTHONPATH:+:$PYTHONPATH}"

if [ -n "${DATABASE_URL:-}" ]; then
  DATABASE_URL="$(normalize_url_value "$DATABASE_URL")"
  DATABASE_URL="$(rewrite_service_host "$DATABASE_URL" "db" "localhost")"
fi
if [ -n "${DATABASE_SYNC_URL:-}" ]; then
  DATABASE_SYNC_URL="$(normalize_url_value "$DATABASE_SYNC_URL")"
  DATABASE_SYNC_URL="$(rewrite_service_host "$DATABASE_SYNC_URL" "db" "localhost")"
fi
if [ -n "${REDIS_URL:-}" ]; then
  REDIS_URL="$(normalize_url_value "$REDIS_URL")"
  REDIS_URL="$(rewrite_service_host "$REDIS_URL" "redis" "localhost")"
fi
if [ -n "${CELERY_BROKER_URL:-}" ]; then
  CELERY_BROKER_URL="$(normalize_url_value "$CELERY_BROKER_URL")"
  CELERY_BROKER_URL="$(rewrite_service_host "$CELERY_BROKER_URL" "redis" "localhost")"
fi
if [ -n "${CELERY_RESULT_BACKEND:-}" ]; then
  CELERY_RESULT_BACKEND="$(normalize_url_value "$CELERY_RESULT_BACKEND")"
  CELERY_RESULT_BACKEND="$(rewrite_service_host "$CELERY_RESULT_BACKEND" "redis" "localhost")"
fi
export DATABASE_URL DATABASE_SYNC_URL REDIS_URL CELERY_BROKER_URL CELERY_RESULT_BACKEND

export DATABASE_URL="${DATABASE_URL:-postgresql+asyncpg://worldengine:worldengine@localhost:5432/worldengine}"
export DATABASE_SYNC_URL="${DATABASE_SYNC_URL:-postgresql://worldengine:worldengine@localhost:5432/worldengine}"
export REDIS_URL="${REDIS_URL:-redis://localhost:6379/0}"
export CELERY_BROKER_URL="${CELERY_BROKER_URL:-$REDIS_URL}"
export CELERY_RESULT_BACKEND="${CELERY_RESULT_BACKEND:-$REDIS_URL}"

db_ready=0
for i in $(seq 1 30); do
  if pg_isready -d "$DATABASE_SYNC_URL" >/dev/null 2>&1; then
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
  if redis-cli -u "$REDIS_URL" ping >/dev/null 2>&1; then
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
