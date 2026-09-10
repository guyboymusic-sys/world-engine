#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "🔧 World Engine - Installation Phase"

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Installing Docker..."
    bash "$ROOT_DIR/scripts/install_docker.sh"
    return
  fi

  if ! docker compose version >/dev/null 2>&1; then
    echo "Docker Compose is not available"
    exit 1
  fi

  local docker_info_output
  if docker_info_output="$(docker info 2>&1)"; then
    return
  fi

  case "$docker_info_output" in
    *"permission denied"*|*"Got permission denied"*)
      echo "Docker is installed but the current user cannot access the Docker daemon"
      exit 1
      ;;
  esac

  echo "Starting Docker..."
  bash "$ROOT_DIR/scripts/install_docker.sh"
}

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

require_docker

docker compose up -d db redis

echo "✅ Installation complete!"
