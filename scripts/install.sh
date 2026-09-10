#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "🔧 World Engine - Installation Phase"

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

if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  bash "$ROOT_DIR/scripts/install_docker.sh"
elif ! docker info >/dev/null 2>&1; then
  echo "Starting Docker..."
  bash "$ROOT_DIR/scripts/install_docker.sh"
elif ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose is not available"
  exit 1
fi

docker compose up -d db redis

echo "✅ Installation complete!"
