#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "🔧 World Engine - Installation Phase"

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "System package installation requires root or sudo"
    exit 1
  fi
}

install_system_packages() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "Automatic package installation currently supports Debian/Ubuntu apt-based systems only"
    exit 1
  fi

  run_as_root apt-get update -qq
  run_as_root apt-get install -y -qq \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    git \
    curl \
    wget \
    postgresql-client \
    redis-tools
}

python_is_supported() {
  "$1" - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
}

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

install_system_packages

if command -v python3.11 >/dev/null 2>&1; then
  PYTHON_BIN="python3.11"
elif command -v python3 >/dev/null 2>&1 && python_is_supported python3; then
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
