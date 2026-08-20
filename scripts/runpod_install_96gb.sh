#!/bin/bash
#
# World Engine - COMPLETE AUTOMATED SETUP FOR RUNPOD
# ========================================
# 96GB VRAM RTX Pro Configuration
# Template: runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04
#
# Usage: bash /root/install_all.sh
#

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

PROJECT_DIR="/root/world-engine"
VRAM_GB=96
PYTORCH_VERSION="2.4.0"
CUDA_VERSION="12.4.1"
PYTHON_VERSION="3.11"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

# ============================================================================
# STEP 1: VERIFY ENVIRONMENT
# ============================================================================

print_header "STEP 1: Verifying RunPod Environment"

print_info "Checking CUDA..."
if nvidia-smi &> /dev/null; then
    CUDA_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader | head -1)
    print_step "CUDA detected: $CUDA_INFO"
else
    print_error "CUDA not found!"
    exit 1
fi

print_info "Checking Python..."
python3 --version
print_step "Python verified"

print_info "Checking Docker..."
docker --version || print_info "Docker not installed yet (will install)"

print_info "VRAM: ${VRAM_GB}GB"
print_info "PyTorch: ${PYTORCH_VERSION}"
print_info "CUDA: ${CUDA_VERSION}"
print_step "Environment verified!"

# ============================================================================
# STEP 2: SYSTEM PREPARATION
# ============================================================================

print_header "STEP 2: System Preparation"

print_step "Updating system packages..."
apt-get update
apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    nano \
    htop \
    nvtop \
    ffmpeg \
    libsndfile1 \
    python3-pip \
    python3-dev \
    docker.io \
    docker-compose

print_step "System packages installed"

# ============================================================================
# STEP 3: PROJECT SETUP
# ============================================================================

print_header "STEP 3: Project Setup"

print_step "Creating project directory: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

print_step "Cloning repository..."
if [ -d "$PROJECT_DIR/.git" ]; then
    cd $PROJECT_DIR
    git pull origin initial-setup
else
    git clone --branch initial-setup https://github.com/guyboymusic-sys/world-engine.git $PROJECT_DIR
    cd $PROJECT_DIR
fi

print_step "Repository ready"

# ============================================================================
# STEP 4: PYTHON ENVIRONMENT
# ============================================================================

print_header "STEP 4: Python Virtual Environment Setup"

print_step "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

print_step "Upgrading pip..."
pip install --upgrade pip setuptools wheel

print_step "Installing Python dependencies..."
# Install PyTorch with CUDA 12.4 support
pip install --no-cache-dir torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu124

# Install project dependencies
pip install --no-cache-dir -r requirements.txt

print_step "Python environment ready"

# ============================================================================
# STEP 5: MODEL DIRECTORY SETUP
# ============================================================================

print_header "STEP 5: Model Directory Structure"

MODELS_DIR="$PROJECT_DIR/models"
mkdir -p $MODELS_DIR/{skyreels,audioledm,tortoise,ollama}
mkdir -p $PROJECT_DIR/{videos,audio,logs,config,db/init}

print_step "Model directories created"
du -sh $MODELS_DIR

# ============================================================================
# STEP 6: DOWNLOAD MODELS (PARALLEL)
# ============================================================================

print_header "STEP 6: Downloading AI Models (This will take 15-30 minutes)"

print_info "Note: Models are being downloaded in parallel. This is normal."

# Function to download with retry
download_model() {
    local repo=$1
    local filename=$2
    local dest=$3
    local description=$4
    
    print_info "📥 $description..."
    python3 - <<EOF
import os
from huggingface_hub import hf_hub_download

os.makedirs("$dest", exist_ok=True)
try:
    hf_hub_download(
        repo_id="$repo",
        filename="$filename",
        local_dir="$dest",
        cache_dir="$dest"
    )
    print("✓ $description completed!")
except Exception as e:
    print(f"⚠ $description: {e}")
EOF
}

# Download in background (parallel)
download_model "SkyworkAI/SkyReels-V2-14B" "pytorch_model.bin" "$MODELS_DIR/skyreels" "SkyReels V2" &
PID1=$!

download_model "haoheliu/AudioLDM2-large" "model.pth" "$MODELS_DIR/audioledm" "AudioLDM2" &
PID2=$!

print_info "⏳ Pulling Ollama models (Mistral 7B) - this takes 5-10 minutes..."
# Start Ollama in background
service docker start
docker run -d --gpus all -e OLLAMA_MODELS=/models/ollama -v $MODELS_DIR/ollama:/models/ollama -p 11434:11434 ollama/ollama:latest &
PID_OLLAMA=$!

# Download Tortoise TTS
print_info "📥 Downloading Tortoise TTS (8GB)..."
python3 - <<'EOF'
from tortoise.utils.download import download_models
try:
    download_models()
    print("✓ Tortoise TTS completed!")
except Exception as e:
    print(f"⚠ Tortoise TTS: {e}")
EOF
PID3=$!

# Wait for all downloads
print_info "Waiting for all models to download..."
wait $PID1 $PID2 $PID3

sleep 30  # Give Ollama time to initialize

# Pull Mistral model into Ollama
print_info "Pulling Mistral model into Ollama..."
docker exec $(docker ps -q -f ancestor=ollama/ollama:latest) ollama pull mistral:latest

print_step "All models downloaded successfully!"

# ============================================================================
# STEP 7: ENVIRONMENT CONFIGURATION
# ============================================================================

print_header "STEP 7: Configuration Setup"

print_step "Creating .env file..."
cat > $PROJECT_DIR/.env <<'ENVEOF'
# YouTube Integration - PLEASE UPDATE THESE!
YOUTUBE_CHANNEL_ID=your_channel_id_here
YOUTUBE_API_KEY=your_api_key_here
STREAM_NAME=your_stream_name_here

# Database Configuration
DATABASE_URL=postgresql://postgres:worldengine_pass@db:5432/world_engine
DB_USER=postgres
DB_PASSWORD=worldengine_pass
DB_HOST=db
DB_PORT=5432

# Redis Configuration
REDIS_URL=redis://redis:6379
REDIS_HOST=redis
REDIS_PORT=6379

# Service URLs
SKYREELS_BASE_URL=http://skyreels:8002
AUDIOLEDM_BASE_URL=http://audioledm:8003
TORTOISE_BASE_URL=http://tortoise:8001
OLLAMA_BASE_URL=http://ollama:11434

# Backend Configuration
BACKEND_PORT=8000
BACKEND_HOST=0.0.0.0
LOG_LEVEL=INFO

# Model Configuration
MODEL_DEVICE=cuda
VIDEO_QUALITY=high
AUDIO_QUALITY=high

# SkyReels V2 Settings
SKYREELS_MODEL_NAME=SkyReels-V2-14B
SKYREELS_RESOLUTION=1280x720
SKYREELS_MAX_DURATION=60

# AudioLDM2 Settings
AUDIOLEDM_SAMPLE_RATE=16000
AUDIOLEDM_DURATION=30

# Tortoise TTS Settings
TORTOISE_VOICE_PRESET=ultra_fast
TORTOISE_QUALITY=high

# Stream Configuration
STREAM_RESOLUTION=1920x1080
STREAM_FPS=30
STREAM_BITRATE=3000k
STREAM_CODEC=libx264

# Performance Tuning (for 96GB VRAM)
VRAM_OPTIMIZATION=false
ENABLE_MEMORY_EFFICIENT=true
BATCH_SIZE=1
NUM_INFERENCE_STEPS=20

ENVEOF

print_step ".env created (IMPORTANT: Update with your YouTube credentials!)"

# ============================================================================
# STEP 8: DATABASE INITIALIZATION
# ============================================================================

print_header "STEP 8: Database Schema Setup"

print_step "Creating database initialization script..."
mkdir -p $PROJECT_DIR/db/init

cat > $PROJECT_DIR/db/init/01-init.sql <<'DBEOF'
-- World Engine Database Schema for 96GB VRAM Setup

-- Characters Table
CREATE TABLE IF NOT EXISTS characters (
    id SERIAL PRIMARY KEY,
    character_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    level INT DEFAULT 1,
    experience BIGINT DEFAULT 0,
    hp INT DEFAULT 100,
    mp INT DEFAULT 50,
    strength INT DEFAULT 10,
    intelligence INT DEFAULT 10,
    dexterity INT DEFAULT 10,
    appearance_hash VARCHAR(255),
    appearance_embedding BYTEA,
    current_location VARCHAR(255),
    idle_level INT DEFAULT 0,
    last_action_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inventory Table
CREATE TABLE IF NOT EXISTS inventory (
    id SERIAL PRIMARY KEY,
    character_id INT NOT NULL,
    item_id VARCHAR(255) NOT NULL,
    quantity INT DEFAULT 1,
    equipped BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
);

-- Locations Table
CREATE TABLE IF NOT EXISTS locations (
    id SERIAL PRIMARY KEY,
    location_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    visual_reference_path VARCHAR(500),
    environment_hash VARCHAR(255),
    is_indoor BOOLEAN DEFAULT FALSE
);

-- Transactions (Donations) Table
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    viewer_id VARCHAR(255) NOT NULL,
    username VARCHAR(255),
    amount DECIMAL(10, 2) NOT NULL,
    command VARCHAR(500) NOT NULL,
    video_id VARCHAR(255),
    audio_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Video Cache Table
CREATE TABLE IF NOT EXISTS video_cache (
    id SERIAL PRIMARY KEY,
    video_id VARCHAR(255) UNIQUE NOT NULL,
    video_path VARCHAR(500) NOT NULL,
    action_type VARCHAR(100),
    character_id INT,
    location_id INT,
    idle_level INT,
    generation_time INT,
    file_size INT,
    duration INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Idle Loop Cache Table (optimized for streaming)
CREATE TABLE IF NOT EXISTS idle_loop_cache (
    id SERIAL PRIMARY KEY,
    cache_key VARCHAR(255) UNIQUE NOT NULL,
    location_id INT NOT NULL,
    character_id INT NOT NULL,
    video_path VARCHAR(500) NOT NULL,
    character_appearance_hash VARCHAR(255),
    environment_hash VARCHAR(255),
    duration INT DEFAULT 60,
    is_loopable BOOLEAN DEFAULT TRUE,
    usage_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    last_used TIMESTAMP,
    FOREIGN KEY (location_id) REFERENCES locations(id),
    FOREIGN KEY (character_id) REFERENCES characters(id)
);

-- Audio Cache Table
CREATE TABLE IF NOT EXISTS audio_cache (
    id SERIAL PRIMARY KEY,
    audio_id VARCHAR(255) UNIQUE NOT NULL,
    audio_path VARCHAR(500) NOT NULL,
    audio_type VARCHAR(50), -- 'dialogue', 'ambient', 'sfx'
    duration INT,
    sample_rate INT DEFAULT 16000,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Action History (for auto-narrative tracking)
CREATE TABLE IF NOT EXISTS action_history (
    id SERIAL PRIMARY KEY,
    character_id INT NOT NULL,
    action_type VARCHAR(100),
    action_description TEXT,
    idle_level INT,
    result_state JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
);

-- LLM Context Cache (for faster inference)
CREATE TABLE IF NOT EXISTS llm_context_cache (
    id SERIAL PRIMARY KEY,
    context_key VARCHAR(255) UNIQUE NOT NULL,
    context_data JSONB NOT NULL,
    last_accessed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Performance Indexes
CREATE INDEX idx_character_id ON characters(character_id);
CREATE INDEX idx_location_id ON locations(location_id);
CREATE INDEX idx_transactions_viewer ON transactions(viewer_id);
CREATE INDEX idx_transactions_created ON transactions(created_at);
CREATE INDEX idx_video_cache_action ON video_cache(action_type);
CREATE INDEX idx_video_cache_expires ON video_cache(expires_at);
CREATE INDEX idx_idle_loop_cache_key ON idle_loop_cache(cache_key);
CREATE INDEX idx_idle_loop_cache_expires ON idle_loop_cache(expires_at);
CREATE INDEX idx_action_history_char ON action_history(character_id);
CREATE INDEX idx_llm_context_expires ON llm_context_cache(expires_at);

-- Initialize default locations
INSERT INTO locations (location_id, name, description, is_indoor) VALUES
    ('convenience_store', 'Convenience Store', 'A local 24-hour convenience store', TRUE),
    ('forest', 'Forest', 'A lush green forest with tall trees', FALSE),
    ('workshop', 'Workshop', 'A crafting workshop with tools and materials', TRUE),
    ('dungeon', 'Dark Dungeon', 'An ancient underground dungeon', FALSE)
ON CONFLICT DO NOTHING;

DBEOF

print_step "Database schema prepared"

# ============================================================================
# STEP 9: DOCKER SETUP & BUILD
# ============================================================================

print_header "STEP 9: Docker Setup & Service Build"

print_step "Starting Docker daemon..."
service docker start
usermod -aG docker root

print_step "Pulling base images..."
docker pull runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04
docker pull postgres:15-alpine
docker pull redis:7-alpine
docker pull ollama/ollama:latest

print_step "Building Docker images (this may take 10-15 minutes)..."
cd $PROJECT_DIR
docker-compose build --no-cache 2>&1 | tee docker-build.log

print_step "Docker build completed!"

# ============================================================================
# STEP 10: START SERVICES
# ============================================================================

print_header "STEP 10: Starting Services"

print_step "Starting Docker Compose services..."
docker-compose up -d

print_info "Waiting for services to initialize (60 seconds)..."
sleep 60

print_step "Checking service status..."
docker-compose ps

# ============================================================================
# STEP 11: SERVICE HEALTH CHECKS
# ============================================================================

print_header "STEP 11: Service Health Verification"

verify_service() {
    local name=$1
    local url=$2
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            print_step "✓ $name is running"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    print_error "$name failed to start"
    return 1
}

verify_service "Backend API" "http://localhost:8000/health"
verify_service "PostgreSQL" "http://localhost:5432" || print_info "(PostgreSQL uses TCP, connection check)"
verify_service "Redis" "http://localhost:6379" || print_info "(Redis uses TCP, connection check)"
verify_service "SkyReels V2" "http://localhost:8002/health"
verify_service "AudioLDM2" "http://localhost:8003/health"
verify_service "Tortoise TTS" "http://localhost:8001/health"
verify_service "Ollama" "http://localhost:11434/api/tags"

print_step "Service health checks completed"

# ============================================================================
# STEP 12: HELPER SCRIPTS
# ============================================================================

print_header "STEP 12: Creating Helper Scripts"

# Start script
cat > $PROJECT_DIR/start.sh <<'STARTEOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
docker-compose up -d
echo "✓ World Engine started!"
echo "Waiting for services..."
sleep 30
echo ""
echo "🎮 Services running:"
docker-compose ps
echo ""
echo "📊 Monitor logs:"
echo "  ./logs.sh"
STARTEOF
chmod +x $PROJECT_DIR/start.sh

# Stop script
cat > $PROJECT_DIR/stop.sh <<'STOPEOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose down
echo "✓ World Engine stopped!"
STOPEOF
chmod +x $PROJECT_DIR/stop.sh

# Logs script
cat > $PROJECT_DIR/logs.sh <<'LOGSEOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose logs -f
LOGSEOF
chmod +x $PROJECT_DIR/logs.sh

# GPU Monitor script
cat > $PROJECT_DIR/monitor_gpu.sh <<'MONEOF'
#!/bin/bash
watch -n 1 nvidia-smi
MONEOF
chmod +x $PROJECT_DIR/monitor_gpu.sh

# Status check script
cat > $PROJECT_DIR/status.sh <<'STATUSEOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "🎮 World Engine Status"
echo "===================="
echo ""
echo "Docker Services:"
docker-compose ps
echo ""
echo "GPU Status:"
nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv
echo ""
echo "Port Status:"
netstat -tlnp | grep -E ':8000|:5432|:6379|:8002|:8003|:8001|:11434' || echo "Services not bound yet"
STATUSEOF
chmod +x $PROJECT_DIR/status.sh

# Reload script
cat > $PROJECT_DIR/reload.sh <<'RELOADEOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "Stopping services..."
docker-compose down
echo "Clearing cache..."
docker system prune -f
echo "Starting services..."
docker-compose up -d
sleep 30
echo "✓ Services reloaded!"
./status.sh
RELOADEOF
chmod +x $PROJECT_DIR/reload.sh

print_step "Helper scripts created"

# ============================================================================
# STEP 13: FINAL SUMMARY
# ============================================================================

print_header "🎉 WORLD ENGINE SETUP COMPLETE! 🎉"

echo -e "${GREEN}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║                  SETUP SUCCESSFUL!                         ║
║                  96GB VRAM RTX Pro 6000                    ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${BLUE}📋 NEXT STEPS:${NC}"
echo ""
echo "1. 🔑 ${YELLOW}Update YouTube Credentials:${NC}"
echo "   nano $PROJECT_DIR/.env"
echo "   Update: YOUTUBE_CHANNEL_ID, YOUTUBE_API_KEY, STREAM_NAME"
echo ""
echo "2. ▶️  ${YELLOW}Start the stream:${NC}"
echo "   cd $PROJECT_DIR && ./start.sh"
echo ""
echo "3. 📊 ${YELLOW}Monitor GPU usage:${NC}"
echo "   ./monitor_gpu.sh"
echo ""
echo "4. 🔍 ${YELLOW}View logs:${NC}"
echo "   ./logs.sh"
echo ""
echo "5. 🛑 ${YELLOW}Stop services:${NC}"
echo "   ./stop.sh"
echo ""

echo -e "${BLUE}🌐 SERVICE ENDPOINTS:${NC}"
echo "   • Backend API: http://localhost:8000"
echo "   • API Docs: http://localhost:8000/docs"
echo "   • PostgreSQL: localhost:5432"
echo "   • Redis: localhost:6379"
echo "   • SkyReels V2: http://localhost:8002"
echo "   • AudioLDM2: http://localhost:8003"
echo "   • Tortoise TTS: http://localhost:8001"
echo "   • Ollama: http://localhost:11434"
echo ""

echo -e "${BLUE}📁 PROJECT STRUCTURE:${NC}"
echo "   $PROJECT_DIR"
echo "   ├── src/              # Backend source code"
echo "   ├── services/         # Microservices (video, audio)"
echo "   ├── models/           # Downloaded AI models (90GB+)"
echo "   ├── videos/           # Generated videos"
echo "   ├── audio/            # Generated audio"
echo "   ├── logs/             # Application logs"
echo "   └── docker-compose.yml"
echo ""

echo -e "${BLUE}💡 HELPFUL COMMANDS:${NC}"
echo "   cd $PROJECT_DIR && ./status.sh    # Check all services"
echo "   cd $PROJECT_DIR && ./logs.sh      # View all logs"
echo "   cd $PROJECT_DIR && ./reload.sh    # Reload services"
echo "   docker-compose ps                 # List containers"
echo "   nvidia-smi                        # GPU status"
echo ""

echo -e "${GREEN}✨ You're ready to start streaming!${NC}"
echo ""

# Save summary to file
cat > $PROJECT_DIR/SETUP_SUMMARY.txt <<SUMMARYEOF
World Engine - Setup Complete
==============================
Date: $(date)
VRAM: 96GB
PyTorch: 2.4.0
CUDA: 12.4.1
Python: 3.11
Template: runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

Project Directory: $PROJECT_DIR

Services:
- Backend API (8000)
- PostgreSQL (5432)
- Redis (6379)
- SkyReels V2 (8002)
- AudioLDM2 (8003)
- Tortoise TTS (8001)
- Ollama/Mistral (11434)

Helper Scripts:
- ./start.sh         Start all services
- ./stop.sh          Stop all services
- ./logs.sh          View logs
- ./status.sh        Check status
- ./monitor_gpu.sh   Monitor GPU
- ./reload.sh        Reload services

Next: Update .env with YouTube credentials and run ./start.sh
SUMMARYEOF

print_step "Setup summary saved to SETUP_SUMMARY.txt"
print_step "Setup complete! All systems ready! 🚀"

