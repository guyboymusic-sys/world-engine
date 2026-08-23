#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
  ╔═════════════════════════════════════════════════════════════╗
  ║                                                             ║
  ║   🚀 World Engine - RTX PRO 6000 Blackwell Setup 🚀        ║
  ║                                                             ║
  ║      RunPod PyTorch 2.4.0 | Python 3.11 | CUDA 12.4        ║
  ║                                                             ║
  ╚═════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""

# Detect RunPod environment
if [ -z "$RUNPOD_POD_ID" ]; then
    echo -e "${YELLOW}⚠️  Not running on RunPod. Some features may not work.${NC}"
fi

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR" || exit 1

echo -e "${BLUE}📂 Project directory: $PROJECT_DIR${NC}"
echo ""

# ============================================================================
# STEP 1: System Dependencies
# ============================================================================
echo -e "${YELLOW}[1/8] Installing system dependencies...${NC}"
apt-get update -qq 2>&1 | tail -2
apt-get install -y \
    sudo git curl wget htop tmux screen \
    postgresql postgresql-contrib redis-server \
    build-essential libssl-dev libffi-dev python3.11-dev \
    2>&1 | grep -E "^(Setting|Processing|$)" | tail -5

echo -e "${GREEN}✅ System dependencies installed${NC}"
echo ""

# ============================================================================
# STEP 2: Sudo Setup
# ============================================================================
echo -e "${YELLOW}[2/8] Configuring sudo...${NC}"
usermod -aG sudo root 2>/dev/null || true
echo -e "${GREEN}✅ Sudo configured${NC}"
echo ""

# ============================================================================
# STEP 3: Python Virtual Environment
# ============================================================================
echo -e "${YELLOW}[3/8] Setting up Python virtual environment...${NC}"
if [ ! -d ".venv" ]; then
    python3.11 -m venv .venv
    echo -e "${GREEN}✅ Virtual environment created${NC}"
else
    echo -e "${BLUE}ℹ️  Virtual environment already exists${NC}"
fi

source .venv/bin/activate
echo ""

# ============================================================================
# STEP 4: Python Dependencies
# ============================================================================
echo -e "${YELLOW}[4/8] Installing Python packages...${NC}"
echo -e "    This may take 5-10 minutes on first run..."
echo ""

pip install --quiet --upgrade pip setuptools wheel

if [ -f "backend/requirements-pinned.txt" ]; then
    pip install --quiet -r backend/requirements-pinned.txt 2>&1 | grep -E "(Successfully|ERROR)" | head -5
    echo -e "${GREEN}✅ Python packages installed from pinned requirements${NC}"
else
    echo -e "${RED}❌ requirements-pinned.txt not found${NC}"
    exit 1
fi
echo ""

# ============================================================================
# STEP 5: PostgreSQL Setup
# ============================================================================
echo -e "${YELLOW}[5/8] Setting up PostgreSQL...${NC}"

# Fix authentication
sudo sed -i 's/peer/trust/g' /etc/postgresql/14/main/pg_hba.conf 2>/dev/null || true

# Start PostgreSQL
service postgresql start 2>&1 | grep -E "(Starting|OK)" || true
sleep 2

# Create database and user
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = 'worldengine'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE worldengine;" 2>/dev/null

sudo -u postgres psql -tc "SELECT 1 FROM pg_user WHERE usename = 'worldengine'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER worldengine WITH PASSWORD 'worldengine';" 2>/dev/null

# Configure user
sudo -u postgres psql -c "ALTER ROLE worldengine SET client_encoding TO 'utf8';" 2>/dev/null || true
sudo -u postgres psql -c "ALTER ROLE worldengine SET default_transaction_isolation TO 'read committed';" 2>/dev/null || true
sudo -u postgres psql -c "ALTER ROLE worldengine SET default_transaction_deferrable TO on;" 2>/dev/null || true
sudo -u postgres psql -c "ALTER ROLE worldengine SET default_transaction_isolation TO 'read uncommitted';" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE worldengine TO worldengine;" 2>/dev/null || true

# Verify
if sudo -u postgres psql -d worldengine -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PostgreSQL ready (port 5432)${NC}"
else
    echo -e "${RED}❌ PostgreSQL connection failed${NC}"
    exit 1
fi
echo ""

# ============================================================================
# STEP 6: Redis Setup
# ============================================================================
echo -e "${YELLOW}[6/8] Setting up Redis...${NC}"

service redis-server start 2>&1 | grep -E "(Starting|OK)" || true
sleep 1

if redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Redis ready (port 6379)${NC}"
else
    echo -e "${YELLOW}⚠️  Redis may need manual restart${NC}"
fi
echo ""

# ============================================================================
# STEP 7: Environment Configuration
# ============================================================================
echo -e "${YELLOW}[7/8] Configuring environment (.env)...${NC}"

if [ ! -f "backend/.env" ]; then
    cp backend/.env.example backend/.env
    echo -e "${GREEN}✅ .env file created from template${NC}"
else
    echo -e "${BLUE}ℹ️  .env file already exists (keeping existing)${NC}"
fi

# Generate secure SECRET_KEY
SECRET_KEY=$(python3 -c "import secrets; print('sk_' + secrets.token_hex(32))")

# Update critical values
sed -i "s|SECRET_KEY=.*|SECRET_KEY=$SECRET_KEY|g" backend/.env
sed -i "s|DATABASE_URL=.*|DATABASE_URL=postgresql://worldengine:worldengine@localhost:5432/worldengine|g" backend/.env
sed -i "s|DATABASE_SYNC_URL=.*|DATABASE_SYNC_URL=postgresql://worldengine:worldengine@localhost:5432/worldengine|g" backend/.env
sed -i "s|REDIS_URL=.*|REDIS_URL=redis://localhost:6379/0|g" backend/.env
sed -i "s|API_BASE_URL=.*|API_BASE_URL=http://localhost:8000/api/v1|g" backend/.env

# RTX PRO 6000 specific settings (optimized for this hardware)
sed -i "s|VIDEO_WORKER_CONCURRENCY=.*|VIDEO_WORKER_CONCURRENCY=2|g" backend/.env
sed -i "s|AUDIO_WORKER_CONCURRENCY=.*|AUDIO_WORKER_CONCURRENCY=4|g" backend/.env
sed -i "s|TTS_WORKER_CONCURRENCY=.*|TTS_WORKER_CONCURRENCY=4|g" backend/.env
sed -i "s|LLM_WORKER_CONCURRENCY=.*|LLM_WORKER_CONCURRENCY=2|g" backend/.env

# Higher quality settings for RTX PRO 6000
sed -i "s|VIDEO_FPS=.*|VIDEO_FPS=30|g" backend/.env
sed -i "s|VIDEO_DURATION_SECONDS=.*|VIDEO_DURATION_SECONDS=10|g" backend/.env

echo -e "${GREEN}✅ Environment configured${NC}"
echo -e "    SECRET_KEY: ${YELLOW}${SECRET_KEY:0:20}...${NC}"
echo ""

# ============================================================================
# STEP 8: Database Migrations
# ============================================================================
echo -e "${YELLOW}[8/8] Running database migrations...${NC}"

export PYTHONPATH="$PROJECT_DIR:$PYTHONPATH"
cd backend

if alembic upgrade head > /tmp/migration.log 2>&1; then
    TABLES=$(sudo -u postgres psql -d worldengine -tc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'")
    echo -e "${GREEN}✅ Database ready ($TABLES tables created)${NC}"
else
    echo -e "${RED}❌ Migration failed${NC}"
    cat /tmp/migration.log
    exit 1
fi

cd ..
echo ""

# ============================================================================
# VERIFICATION
# ============================================================================
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ SETUP COMPLETE!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}🖥️  System Information:${NC}"
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader | while read line; do
    echo -e "    GPU: ${CYAN}$line${NC}"
done
echo -e "    vCPU: ${CYAN}28 (AMD EPYC 9554)${NC}"
echo -e "    RAM: ${CYAN}221 GB${NC}"
echo -e "    Disk: ${CYAN}50 GB root + 150 GB /workspace${NC}"
echo ""

echo -e "${BLUE}🔗 Running Services:${NC}"
for service in postgresql redis-server; do
    if service $service status 2>&1 | grep -q "running\|online"; then
        echo -e "    ${GREEN}✓${NC} $service"
    else
        echo -e "    ${RED}✗${NC} $service"
    fi
done
echo ""

echo -e "${BLUE}📋 Environment Variables:${NC}"
echo -e "    DATABASE_URL: ${CYAN}postgresql://worldengine:***@localhost:5432/worldengine${NC}"
echo -e "    REDIS_URL: ${CYAN}redis://localhost:6379/0${NC}"
echo -e "    API_BASE_URL: ${CYAN}http://localhost:8000/api/v1${NC}"
echo ""

echo -e "${BLUE}⚙️  Worker Configuration (RTX PRO 6000 optimized):${NC}"
grep -E "(VIDEO|AUDIO|TTS|LLM)_WORKER_CONCURRENCY" backend/.env | sed "s/^/    /"
echo ""

echo -e "${YELLOW}🚀 Next Steps (open 3 terminals):${NC}"
echo ""

echo -e "${CYAN}Terminal 1 - API Server:${NC}"
cat << 'SHELL'
    cd /workspace/world-engine
    source .venv/bin/activate
    export PYTHONPATH=/workspace/world-engine:$PYTHONPATH
    cd backend
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload
SHELL
echo ""

echo -e "${CYAN}Terminal 2 - Celery Worker:${NC}"
cat << 'SHELL'
    cd /workspace/world-engine
    source .venv/bin/activate
    export PYTHONPATH=/workspace/world-engine:$PYTHONPATH
    cd backend
    celery -A celery_app worker --loglevel=info --concurrency=12
SHELL
echo ""

echo -e "${CYAN}Terminal 3 - Monitor/Test:${NC}"
cat << 'SHELL'
    # Check API health
    curl http://localhost:8000/health
    
    # View Celery tasks
    celery -A backend.celery_app inspect active
    
    # Monitor GPU usage
    nvidia-smi -l 1
SHELL
echo ""

echo -e "${BLUE}📚 API Documentation & Tools:${NC}"
echo -e "    • Swagger UI: ${CYAN}http://localhost:8000/docs${NC}"
echo -e "    • ReDoc: ${CYAN}http://localhost:8000/redoc${NC}"
echo -e "    • Flower (Celery): ${CYAN}http://localhost:5555${NC} (run: celery -A backend.celery_app flower)"
echo ""

echo -e "${BLUE}💾 Database Utilities:${NC}"
echo -e "    Connect to DB:"
echo -e "        ${CYAN}psql -U worldengine -d worldengine${NC}"
echo ""
echo -e "    View tables:"
echo -e "        ${CYAN}sudo -u postgres psql -d worldengine -c '\\dt'${NC}"
echo ""
echo -e "    Reset database (⚠️ destructive):"
echo -e "        ${CYAN}sudo -u postgres dropdb worldengine${NC}"
echo -e "        ${CYAN}cd backend && alembic upgrade head${NC}"
echo ""

echo -e "${BLUE}📊 Performance Monitoring:${NC}"
echo -e "    GPU usage: ${CYAN}nvidia-smi -l 1${NC}"
echo -e "    GPU processes: ${CYAN}nvidia-smi pmon${NC}"
echo -e "    CPU/RAM: ${CYAN}htop${NC}"
echo -e "    Disk: ${CYAN}df -h${NC}"
echo ""

echo -e "${YELLOW}💡 Tips for RTX PRO 6000:${NC}"
echo -e "    • GPU Memory: 48 GB (plenty for all models)"
echo -e "    • Can run multiple workers in parallel"
echo -e "    • Increase WORKER_CONCURRENCY for faster processing"
echo -e "    • Monitor nvidia-smi during heavy load"
echo ""

echo -e "${BLUE}🔧 Environment Info Saved:${NC}"
echo -e "    • Config: ${CYAN}backend/.env${NC}"
echo -e "    • Logs: ${CYAN}Check terminal output${NC}"
echo -e "    • Issues: ${CYAN}See INSTALL_ISSUES_AND_FIXES.md${NC}"
echo ""

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}You're all set! 🎉 Start the servers in different terminals.${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
