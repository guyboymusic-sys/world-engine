# Installation Issues & Fixes (RunPod Non-Docker Setup)

## สรุปปัญหาที่เจอในวันนี้

### 🔴 **ปัญหา #1: Docker ไม่มีใน RunPod GPU Container**
**สาเหตุ:** RunPod ใช้ Docker จัดการ container เอง ไม่ติดตั้ง Docker ข้างในเพิ่มเติม

**ผลกระทบ:** 
- `docker --version` → `command not found`
- `docker compose up` ใช้ไม่ได้

**วิธีแก้:** ติดตั้ง Docker + Compose ใน RunPod
```bash
apt-get update
apt-get install -y sudo docker.io docker-compose-plugin
usermod -aG sudo root
```

---

### 🔴 **ปัญหา #2: Dependencies Conflict (transformers version)**
**สาเหตุ:** `tortoise-tts 3.0.0` ต้อง `transformers==4.31.0` แต่ requirements บอก `4.39.3`

**ผลกระทบ:**
```
ERROR: ResolutionImpossible: tortoise-tts 3.0.0 depends on transformers==4.31.0
```

**วิธีแก้:** ใช้ `requirements-pinned.txt` แทน (มี fix ไว้แล้ว)
```bash
pip install -r backend/requirements-pinned.txt
```

---

### 🔴 **ปัญหา #3: PostgreSQL Authentication ผิด**
**สาเหตุ:** หลังจากเปลี่ยน `pg_hba.conf` เป็น `md5` ต้องตั้ง password แต่ไม่มี password เดิม

**ผลกระทบ:**
```
FATAL:  password authentication failed for user "postgres"
```

**วิธีแก้:** เปลี่ยน auth method เป็น `trust` (trusted connections)
```bash
sudo sed -i 's/peer/trust/g' /etc/postgresql/14/main/pg_hba.conf
sudo service postgresql restart
```

---

### 🔴 **ปัญหา #4: Python Import Path ผิด**
**สาเหตุ:** `uvicorn main:app` รันจาก `backend/` directory แต่ import ต้องให้ PYTHONPATH ถูก

**ผลกระทบ:**
```
ModuleNotFoundError: No module named 'backend'
```

**วิธีแก้:** ตั้งค่า PYTHONPATH และรันจากโปรเจกต์ root
```bash
export PYTHONPATH=/workspace/world-engine:$PYTHONPATH
cd /workspace/world-engine
uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```

---

### 🔴 **ปัญหา #5: Health Endpoint ไม่ตรง**
**สาเหตุ:** ทดสอบ `/api/v1/health` แต่ถูกต้องคือ `/health`

**วิธีแก้:** ใช้ endpoint ที่ถูก
```bash
curl http://localhost:8000/health
```

---

## ✅ วิธีแก้เพื่อ "One-Click Install"

### Step 1: สร้าง Setup Script ที่ใช้ได้

สร้างไฟล์: `scripts/setup-runpod-native.sh`
```bash
#!/bin/bash
set -e

echo "🚀 World Engine - RunPod Native Setup (No Docker)"

# 1. Install sudo & Docker
echo "📦 Installing prerequisites..."
apt-get update
apt-get install -y sudo docker.io docker-compose-plugin
usermod -aG sudo root

# 2. Clone/Setup project
PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

# 3. Create venv
echo "🐍 Creating Python venv..."
python3.11 -m venv .venv
source .venv/bin/activate

# 4. Install dependencies
echo "📚 Installing Python packages..."
pip install -r backend/requirements-pinned.txt

# 5. Setup PostgreSQL
echo "🗄️ Setting up PostgreSQL..."
apt-get install -y postgresql postgresql-contrib
sudo sed -i 's/peer/trust/g' /etc/postgresql/14/main/pg_hba.conf
service postgresql start

# 6. Create database
echo "🔧 Creating database..."
sudo -u postgres psql -c "CREATE DATABASE worldengine;" || true
sudo -u postgres psql -c "CREATE USER worldengine WITH PASSWORD 'worldengine';" || true
sudo -u postgres psql -c "ALTER ROLE worldengine SET client_encoding TO 'utf8';" || true
sudo -u postgres psql -c "ALTER ROLE worldengine SET default_transaction_isolation TO 'read committed';" || true
sudo -u postgres psql -c "ALTER ROLE worldengine SET default_transaction_deferrable TO on;" || true
sudo -u postgres psql -c "ALTER ROLE worldengine SET default_transaction_isolation TO 'read uncommitted';" || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE worldengine TO worldengine;" || true

# 7. Setup Redis
echo "🔴 Setting up Redis..."
apt-get install -y redis-server
service redis-server start

# 8. Setup environment
echo "⚙️ Configuring environment..."
cp backend/.env.example backend/.env 2>/dev/null || true

# Generate random secret key
SECRET_KEY=$(python3 -c "import secrets; print('sk_live_' + secrets.token_hex(32))")
sed -i "s|SECRET_KEY=.*|SECRET_KEY=$SECRET_KEY|g" backend/.env
sed -i "s|DATABASE_URL=.*|DATABASE_URL=postgresql://worldengine:worldengine@localhost:5432/worldengine|g" backend/.env
sed -i "s|DATABASE_SYNC_URL=.*|DATABASE_SYNC_URL=postgresql://worldengine:worldengine@localhost:5432/worldengine|g" backend/.env
sed -i "s|REDIS_URL=.*|REDIS_URL=redis://localhost:6379/0|g" backend/.env
sed -i "s|API_BASE_URL=.*|API_BASE_URL=http://localhost:8000/api/v1|g" backend/.env

# 9. Run migrations
echo "🔄 Running database migrations..."
export PYTHONPATH="$PROJECT_DIR:$PYTHONPATH"
cd backend
alembic upgrade head
cd ..

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Terminal 1 (API): export PYTHONPATH=$PROJECT_DIR:\$PYTHONPATH && cd $PROJECT_DIR && source .venv/bin/activate && cd backend && uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
echo "  2. Terminal 2 (Celery): cd $PROJECT_DIR && source .venv/bin/activate && cd backend && celery -A celery_app worker -l info"
echo "  3. Terminal 3 (Test): curl http://localhost:8000/health"
echo ""
echo "🎯 Services running on:"
echo "  • API: http://localhost:8000"
echo "  • PostgreSQL: localhost:5432"
echo "  • Redis: localhost:6379"
echo ""
```

---

### Step 2: สร้าง Docker Compose Alternative (ถ้า Docker ใช้ได้)

**สำหรับผู้ใช้ที่มี Docker:**
```bash
docker compose -f docker-compose-runpod.yml up -d
```

---

### Step 3: สร้าง Startup Script ที่ง่าย

สร้างไฟล์: `scripts/start-all.sh`
```bash
#!/bin/bash

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"
export PYTHONPATH="$PROJECT_DIR:$PYTHONPATH"
source .venv/bin/activate

# Ensure services running
service postgresql start 2>/dev/null || true
service redis-server start 2>/dev/null || true

echo "🚀 Starting World Engine..."
echo "   API on http://localhost:8000"
echo "   Docs on http://localhost:8000/docs"
echo ""

# Terminal multiplexer setup (tmux or screen)
# For now, just run in foreground with instructions

cd backend
echo "Starting API server... (Press Ctrl+C to stop)"
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 📝 Updated QUICK_START_GUIDE.md

เพิ่มสำหรับ **RunPod Native (Non-Docker)** users:

```markdown
## Option A: With Docker (if available)
```bash
docker compose up -d
curl http://localhost:8000/health
```

## Option B: Without Docker (RunPod Native)
```bash
bash scripts/setup-runpod-native.sh $(pwd)
# Then follow instructions for running API + Celery in separate terminals
```
```

---

## 📊 Summary Table

| ปัญหา | สาเหตุ | วิธีแก้ |
|---|---|---|
| Docker ไม่มี | RunPod ไม่ติดตั้ง | `apt-get install docker.io` |
| Dependencies conflict | transformers version ไม่ตรง | ใช้ `requirements-pinned.txt` |
| PostgreSQL auth fail | pg_hba.conf ผิด | เปลี่ยน `peer` → `trust` |
| Import path ผิด | PYTHONPATH ไม่ถูก | ตั้ง PYTHONPATH + รันจาก root |
| Health endpoint ไม่เจอ | Path ผิด | ใช้ `/health` แทน `/api/v1/health` |

---

## 🎯 One-Click Installation

สุดท้าย จะสร้างเป็น:

```bash
# Clone
git clone https://github.com/guyboymusic-sys/world-engine.git
cd world-engine

# One command!
bash scripts/setup-runpod-native.sh $(pwd)

# Done! ✅
```

