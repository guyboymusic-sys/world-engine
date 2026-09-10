#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "🚀 World Engine - Running Phase"

if [ ! -f ".venv/bin/activate" ]; then
  echo "Virtual environment is missing. Run bash scripts/install.sh first."
  exit 1
fi

echo "✅ Starting API Server..."
echo "✅ Starting Celery workers..."
echo "🎬 World Engine Ready!"
echo "📺 API:        http://localhost:${FASTAPI_PORT:-8000}"
echo "📊 Docs:       http://localhost:${FASTAPI_PORT:-8000}/docs"
echo "🟢 Redis:      redis://localhost:6379/0"
echo "🐘 PostgreSQL: localhost:5432"

exec bash "$ROOT_DIR/scripts/run_all.sh"
