#!/usr/bin/env bash
# setup.sh – Full environment setup for World Engine
# Requirements: Python 3.11+, Docker, Docker Compose v2, nvidia-container-toolkit (for GPU)

set -euo pipefail

echo "=== World Engine Setup ==="

# 1. Copy env file
if [ ! -f backend/.env ]; then
    cp backend/.env.example backend/.env
    echo "[1/5] Created backend/.env – please edit it with your secrets before continuing."
    echo "      Press Enter to continue once done, or Ctrl+C to abort."
    read -r
else
    echo "[1/5] backend/.env already exists, skipping."
fi

# 2. Create Python virtualenv and install deps
echo "[2/5] Installing Python dependencies..."
python3 -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate
pip install --upgrade pip
pip install -r backend/requirements.txt

# 3. Download AI models
echo "[3/5] Downloading AI models (this may take a long time)..."
bash scripts/install_models.sh /models

# 4. Start infrastructure services
echo "[4/5] Starting Docker services (db, redis, nginx-rtmp)..."
docker compose up -d db redis nginx-rtmp
echo "      Waiting for DB to be ready..."
sleep 10

# 5. Run database migrations
echo "[5/5] Running database migrations..."
export DATABASE_URL=$(grep DATABASE_URL backend/.env | cut -d= -f2-)
alembic upgrade head

echo ""
echo "=== Setup complete! ==="
echo "Start API:     uvicorn backend.main:app --host 0.0.0.0 --port 8000"
echo "Start workers: docker compose up -d worker-video worker-audio worker-tts worker-llm"
echo "Full stack:    docker compose up -d"
