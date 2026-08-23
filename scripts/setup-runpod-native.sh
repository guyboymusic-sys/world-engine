#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 World Engine - RunPod Native Setup (No Docker)${NC}"
echo ""

# Determine project directory
PROJECT_DIR="${1:-.}"
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ Project directory not found: $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"
echo -e "${BLUE}📂 Working directory: $PROJECT_DIR${NC}"
echo ""

# Step 1: Install system dependencies
echo -e "${YELLOW}📦 Step 1: Installing system dependencies...${NC}"
apt-get update -qq
apt-get install -y sudo docker.io docker-compose-plugin postgresql postgresql-contrib redis-server 2>/dev/null | tail -5
usermod -aG sudo root 2>/dev/null || true
echo -e "${GREEN}✅ System dependencies installed${NC}"
echo ""

# Step 2: Create Python venv
echo -e "${YELLOW}🐍 Step 2: Setting up Python environment...${NC}"
if [ ! -d ".venv" ]; then
    python3.11 -m venv .venv
    echo -e "${GREEN}✅ Virtual environment created${NC}"
else
    echo -e "${BLUE}ℹ️  Virtual environment already exists${NC}"
fi
source .venv/bin/activate
echo ""

# Step 3: Install Python dependencies
echo -e "${YELLOW}📚 Step 3: Installing Python packages...${NC}"
pip install -q -r backend/requirements-pinned.txt
echo -e "${GREEN}✅ Python packages installed${NC}"
echo ""

# Step 4: Setup PostgreSQL
echo -e "${YELLOW}🗄️  Step 4: Setting up PostgreSQL...${NC}"
sudo sed -i 's/peer/trust/g' /etc/postgresql/14/main/pg_hba.conf 2>/dev/null || true
service postgresql start 2>/dev/null || true
sleep 2

# Create database and user
sudo -u postgres psql -c "CREATE DATABASE worldengine;" 2>/dev/null || echo "  ℹ️  Database already exists"
sudo -u postgres psql -c "CREATE USER worldengine WITH PASSWORD 'worldengine';" 2>/dev/null || echo "  ℹ️  User already exists"
sudo -u postgres psql -c "ALTER ROLE worldengine SET client_encoding TO 'utf8';" 2>/dev/null || true
sudo -u postgres psql -c "ALTER ROLE worldengine SET default_transaction_isolation TO 'read committed';" 2>/dev/null || true
sudo -u postgres psql -c "ALTER ROLE worldengine SET default_transaction_deferrable TO on;" 2>/dev/null || true
sudo -u postgres psql -c "ALTER ROLE worldengine SET default_transaction_isolation TO 'read uncommitted';" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE worldengine TO worldengine;" 2>/dev/null || true

# Verify connection
if sudo -u postgres psql -d worldengine -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PostgreSQL configured${NC}"
else
    echo -e "${RED}❌ PostgreSQL connection failed${NC}"
    exit 1
fi
echo ""

# Step 5: Setup Redis
echo -e "${YELLOW}🔴 Step 5: Setting up Redis...${NC}"
service redis-server start 2>/dev/null || true
sleep 1
if redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Redis running${NC}"
else
    echo -e "${YELLOW}⚠️  Redis may not be responding${NC}"
fi
echo ""

# Step 6: Setup environment file
echo -e "${YELLOW}⚙️  Step 6: Configuring environment...${NC}"
if [ ! -f "backend/.env" ]; then
    cp backend/.env.example backend/.env
    echo -e "${GREEN}✅ .env file created${NC}"
else
    echo -e "${BLUE}ℹ️  .env file already exists${NC}"
fi

# Generate random SECRET_KEY
SECRET_KEY=$(python3 -c "import secrets; print('sk_live_' + secrets.token_hex(32))")
sed -i "s|SECRET_KEY=.*|SECRET_KEY=$SECRET_KEY|g" backend/.env
sed -i "s|DATABASE_URL=.*|DATABASE_URL=postgresql://worldengine:worldengine@localhost:5432/worldengine|g" backend/.env
sed -i "s|DATABASE_SYNC_URL=.*|DATABASE_SYNC_URL=postgresql://worldengine:worldengine@localhost:5432/worldengine|g" backend/.env
sed -i "s|REDIS_URL=.*|REDIS_URL=redis://localhost:6379/0|g" backend/.env
sed -i "s|API_BASE_URL=.*|API_BASE_URL=http://localhost:8000/api/v1|g" backend/.env

echo -e "${GREEN}✅ Environment configured${NC}"
echo ""

# Step 7: Run Alembic migrations
echo -e "${YELLOW}🔄 Step 7: Running database migrations...${NC}"
export PYTHONPATH="$PROJECT_DIR:$PYTHONPATH"
cd backend
if alembic upgrade head 2>&1 | grep -q "ERROR"; then
    echo -e "${RED}❌ Migration failed${NC}"
    exit 1
fi
cd ..
echo -e "${GREEN}✅ Database migrations completed${NC}"
echo ""

# Summary
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}📋 Running Services:${NC}"
echo -e "  • ${GREEN}✓${NC} PostgreSQL: localhost:5432"
echo -e "  • ${GREEN}✓${NC} Redis: localhost:6379"
echo -e "  • ${GREEN}✓${NC} Python venv: activated"
echo ""

echo -e "${BLUE}🚀 Next Steps (run in separate terminals):${NC}"
echo ""

echo -e "${YELLOW}Terminal 1 - FastAPI Server:${NC}"
echo "  export PYTHONPATH=$PROJECT_DIR:\$PYTHONPATH"
echo "  cd $PROJECT_DIR"
echo "  source .venv/bin/activate"
echo "  cd backend"
echo "  uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
echo ""

echo -e "${YELLOW}Terminal 2 - Celery Worker:${NC}"
echo "  export PYTHONPATH=$PROJECT_DIR:\$PYTHONPATH"
echo "  cd $PROJECT_DIR"
echo "  source .venv/bin/activate"
echo "  cd backend"
echo "  celery -A celery_app worker -l info"
echo ""

echo -e "${YELLOW}Terminal 3 - Test API:${NC}"
echo "  curl http://localhost:8000/health"
echo ""

echo -e "${BLUE}📚 API Documentation:${NC}"
echo "  http://localhost:8000/docs"
echo ""

echo -e "${BLUE}📊 Monitoring:${NC}"
echo "  Flower (Celery): http://localhost:5555 (if started)"
echo ""

echo -e "${YELLOW}💡 Tips:${NC}"
echo "  • Keep services running: service postgresql status && service redis-server status"
echo "  • View logs: tail -f /var/log/postgresql/postgresql.log"
echo "  • Reset database: sudo -u postgres dropdb worldengine && alembic upgrade head"
echo ""
