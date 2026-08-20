#!/bin/bash
#
# World Engine - COMPLETE AUTOMATED SETUP SCRIPT
# Run this ONCE on your RunPod RTX Pro 6000 and everything sets up!
#
# Usage: bash install_all.sh
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
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

# Check if running as root (optional but recommended)
if [ "$EUID" -eq 0 ]; then 
    print_info "Running as root (optional)"
fi

# ============================================================================
# STEP 1: SYSTEM UPDATES & DEPENDENCIES
# ============================================================================
print_header "STEP 1: System Updates & Dependencies"

print_step "Updating system packages..."
apt-get update
apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    nano \
    htop \
    nvidia-utils \
    ffmpeg \
    python3-pip \
    python3-dev \
    python3-venv \
    docker.io \
    docker-compose

print_step "System packages installed"

# ============================================================================
# STEP 2: SETUP PROJECT DIRECTORY
# ============================================================================
print_header "STEP 2: Setting Up Project Directory"

PROJECT_DIR="/root/world-engine"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

print_step "Project directory created: $PROJECT_DIR"

# Clone or update repository
if [ -d "$PROJECT_DIR/.git" ]; then
    print_info "Repository already exists, updating..."
    git pull origin initial-setup
else
    print_step "Cloning repository..."
    git clone --branch initial-setup https://github.com/guyboymusic-sys/world-engine.git .
fi

print_step "Repository setup complete"

# ============================================================================
# STEP 3: PYTHON VIRTUAL ENVIRONMENT
# ============================================================================
print_header "STEP 3: Python Virtual Environment"

print_step "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

print_step "Installing Python dependencies..."
pip install --upgrade pip setuptools wheel

# Core dependencies
pip install -r requirements.txt

print_step "Python environment ready"

# ============================================================================
# STEP 4: DOWNLOAD AI MODELS
# ============================================================================
print_header "STEP 4: Downloading AI Models (This takes 10-20 minutes)"

MODELS_DIR="$PROJECT_DIR/models"
mkdir -p $MODELS_DIR

print_info "Creating model directories..."
mkdir -p $MODELS_DIR/skyreels
mkdir -p $MODELS_DIR/ollama
mkdir -p $MODELS_DIR/audioledm
mkdir -p $MODELS_DIR/tortoise

print_step "Model directories created"

# Download SkyReels V2
print_info "Downloading SkyReels V2 (6.9GB)... this may take 5-10 minutes"
python3 - <<'EOF'
from huggingface_hub import hf_hub_download
import os

model_dir = os.path.expanduser("~/world-engine/models/skyreels")
os.makedirs(model_dir, exist_ok=True)

print("⏳ Downloading SkyReels V2 model weights...")
hf_hub_download(
    repo_id="SkyworkAI/SkyReels-V2-14B",
    filename="pytorch_model.bin",
    local_dir=model_dir,
    cache_dir=model_dir
)
print("✓ SkyReels V2 downloaded successfully!")
EOF

# Download Mistral 7B via Ollama
print_info "Setting up Mistral 7B LLM... this may take 5-10 minutes"
print_info "Note: First-time model pull with Ollama may take longer"

# Start ollama in background (if needed)
if ! command -v ollama &> /dev/null; then
    print_info "Installing Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh
fi

# Pre-download model
print_step "Pulling Mistral 7B model... (this is normal, takes time)"
ollama pull mistral:latest &
OLLAMA_PID=$!

# Download AudioLDM2
print_info "Downloading AudioLDM2 (2.5GB)..."
python3 - <<'EOF'
from huggingface_hub import hf_hub_download
import os

model_dir = os.path.expanduser("~/world-engine/models/audioledm")
os.makedirs(model_dir, exist_ok=True)

print("⏳ Downloading AudioLDM2 model...")
hf_hub_download(
    repo_id="haoheliu/AudioLDM2-large",
    filename="model.pth",
    local_dir=model_dir,
    cache_dir=model_dir
)
print("✓ AudioLDM2 downloaded successfully!")
EOF

# Download Tortoise TTS
print_info "Downloading Tortoise TTS (8GB)..."
python3 - <<'EOF'
from tortoise.utils.download import download_models
print("⏳ Downloading Tortoise TTS models...")
download_models()
print("✓ Tortoise TTS downloaded successfully!")
EOF

# Wait for Ollama to finish
print_info "Waiting for Ollama model download to complete..."
wait $OLLAMA_PID
print_step "All models downloaded successfully!"

# ============================================================================
# STEP 5: SETUP DOCKER & SERVICES
# ============================================================================
print_header "STEP 5: Setting Up Docker Services"

print_step "Starting Docker daemon..."
service docker start
usermod -aG docker root

print_step "Building Docker images..."
docker-compose build

print_info "Note: First build may take 5-10 minutes..."
print_step "Docker build complete!"

# ============================================================================
# STEP 6: SETUP DATABASE
# ============================================================================
print_header "STEP 6: Setting Up Database"

print_step "Creating PostgreSQL initialization scripts..."
mkdir -p $PROJECT_DIR/db/init

cat > $PROJECT_DIR/db/init/01-init.sql <<'DBEOF'
-- Create World Engine Database Schema

-- Characters Table
CREATE TABLE IF NOT EXISTS characters (
    id SERIAL PRIMARY KEY,
    character_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    level INT DEFAULT 1,
    experience INT DEFAULT 0,
    hp INT DEFAULT 100,
    mp INT DEFAULT 50,
    strength INT DEFAULT 10,
    intelligence INT DEFAULT 10,
    dexterity INT DEFAULT 10,
    appearance_hash VARCHAR(255),
    appearance_embedding BYTEA,
    current_location VARCHAR(255),
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
    FOREIGN KEY (character_id) REFERENCES characters(id)
);

-- Items Table
CREATE TABLE IF NOT EXISTS items (
    id SERIAL PRIMARY KEY,
    item_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100),
    rarity VARCHAR(50),
    description TEXT
);

-- Locations Table
CREATE TABLE IF NOT EXISTS locations (
    id SERIAL PRIMARY KEY,
    location_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    visual_reference_path VARCHAR(500),
    environment_hash VARCHAR(255)
);

-- Transactions Table (donations)
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    viewer_id VARCHAR(255) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    command VARCHAR(500) NOT NULL,
    video_id VARCHAR(255),
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
    generation_time INT,
    file_size INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Idle Loop Cache Table
CREATE TABLE IF NOT EXISTS idle_loop_cache (
    id SERIAL PRIMARY KEY,
    location_id INT NOT NULL,
    character_id INT NOT NULL,
    video_path VARCHAR(500) NOT NULL,
    character_appearance_hash VARCHAR(255),
    environment_hash VARCHAR(255),
    duration INT DEFAULT 60,
    is_loopable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    last_used TIMESTAMP,
    FOREIGN KEY (location_id) REFERENCES locations(id),
    FOREIGN KEY (character_id) REFERENCES characters(id)
);

-- Action History Table
CREATE TABLE IF NOT EXISTS action_history (
    id SERIAL PRIMARY KEY,
    character_id INT NOT NULL,
    action_type VARCHAR(100),
    action_description TEXT,
    result VARCHAR(500),
    idle_level INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (character_id) REFERENCES characters(id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_character_id ON characters(character_id);
CREATE INDEX IF NOT EXISTS idx_location_id ON locations(location_id);
CREATE INDEX IF NOT EXISTS idx_transactions_viewer ON transactions(viewer_id);
CREATE INDEX IF NOT EXISTS idx_video_cache_action ON video_cache(action_type);
CREATE INDEX IF NOT EXISTS idx_action_history_char ON action_history(character_id);

DBEOF

print_step "Database schema initialized"

# ============================================================================
# STEP 7: ENVIRONMENT CONFIGURATION
# ============================================================================
print_header "STEP 7: Environment Configuration"

print_step "Creating .env file..."
cat > $PROJECT_DIR/.env <<'ENVEOF'
# YouTube Integration
YOUTUBE_CHANNEL_ID=your_channel_id_here
YOUTUBE_API_KEY=your_api_key_here
STREAM_NAME=your_stream_name_here

# Database
DATABASE_URL=postgresql://postgres:password@db:5432/world_engine
DB_USER=postgres
DB_PASSWORD=password

# Redis
REDIS_URL=redis://redis:6379

# Service URLs
SKYREELS_BASE_URL=http://skyreels:8002
AUDIOLEDM_BASE_URL=http://audioledm:8003
TORTOISE_BASE_URL=http://tortoise:8001
OLLAMA_BASE_URL=http://ollama:11434

# Backend
BACKEND_PORT=8000
BACKEND_HOST=0.0.0.0

# Model Settings
MODEL_DEVICE=cuda
VIDEO_QUALITY=high
AUDIO_QUALITY=high

# Stream Settings
STREAM_RESOLUTION=1920x1080
STREAM_FPS=30
STREAM_BITRATE=3000k

ENVEOF

print_step ".env file created (IMPORTANT: Update with your YouTube credentials!)"

# ============================================================================
# STEP 8: START SERVICES
# ============================================================================
print_header "STEP 8: Starting Services"

print_step "Starting Docker Compose services..."
cd $PROJECT_DIR
docker-compose up -d

print_info "Waiting for services to be ready... (takes 30-60 seconds)"
sleep 60

# Check service status
print_step "Service Status:"
docker-compose ps

# ============================================================================
# STEP 9: VERIFICATION
# ============================================================================
print_header "STEP 9: Verification"

print_info "Testing service connectivity..."

# Test Backend
if curl -s http://localhost:8000/health > /dev/null; then
    print_step "✓ Backend API is running"
else
    print_error "Backend API failed to respond"
fi

# Test PostgreSQL
if docker exec world-engine-db-1 pg_isready -U postgres > /dev/null 2>&1; then
    print_step "✓ PostgreSQL is running"
else
    print_error "PostgreSQL failed to respond"
fi

# Test Redis
if redis-cli ping > /dev/null 2>&1; then
    print_step "✓ Redis is running"
else
    print_error "Redis failed to respond"
fi

# Test Ollama (LLM)
if curl -s http://localhost:11434/api/tags > /dev/null; then
    print_step "✓ Ollama (LLM) is running"
else
    print_error "Ollama failed to respond"
fi

# ============================================================================
# STEP 10: FINAL SETUP
# ============================================================================
print_header "STEP 10: Final Setup & Instructions"

print_step "Creating helpful scripts..."

# Create start script
cat > $PROJECT_DIR/start.sh <<'STARTEOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose up -d
echo "✓ World Engine started!"
docker-compose logs -f backend
STARTEOF

chmod +x $PROJECT_DIR/start.sh

# Create stop script
cat > $PROJECT_DIR/stop.sh <<'STOPEOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose down
echo "✓ World Engine stopped!"
STOPEOF

chmod +x $PROJECT_DIR/stop.sh

# Create logs script
cat > $PROJECT_DIR/logs.sh <<'LOGSEOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose logs -f
LOGSEOF

chmod +x $PROJECT_DIR/logs.sh

print_step "Helper scripts created"

# ============================================================================
# COMPLETION MESSAGE
# ============================================================================

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}     🎉 WORLD ENGINE SETUP COMPLETE! 🎉"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📋 NEXT STEPS:${NC}"
echo ""
echo "1. ${YELLOW}Update your YouTube credentials:${NC}"
echo "   nano $PROJECT_DIR/.env"
echo "   • Set YOUTUBE_CHANNEL_ID"
echo "   • Set YOUTUBE_API_KEY"
echo "   • Set STREAM_NAME"
echo ""
echo "2. ${YELLOW}Start the stream:${NC}"
echo "   $PROJECT_DIR/start.sh"
echo ""
echo "3. ${YELLOW}View logs:${NC}"
echo "   $PROJECT_DIR/logs.sh"
echo ""
echo "4. ${YELLOW}Access the backend:${NC}"
echo "   http://localhost:8000/docs (API documentation)"
echo "   http://localhost:8000/health (Health check)"
echo ""
echo "5. ${YELLOW}Stop services:${NC}"
echo "   $PROJECT_DIR/stop.sh"
echo ""
echo -e "${BLUE}📊 SERVICES RUNNING:${NC}"
echo "   • Backend API: http://localhost:8000"
echo "   • PostgreSQL: localhost:5432"
echo "   • Redis: localhost:6379"
echo "   • SkyReels V2: http://localhost:8002"
echo "   • AudioLDM2: http://localhost:8003"
echo "   • Tortoise TTS: http://localhost:8001"
echo "   • Ollama (LLM): http://localhost:11434"
echo ""
echo -e "${BLUE}📁 PROJECT DIRECTORY:${NC}"
echo "   $PROJECT_DIR"
echo ""
echo -e "${GREEN}✓ All systems ready for World Engine streaming!${NC}"
echo ""
