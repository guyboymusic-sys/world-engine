# 🎮 World Engine - QUICK START GUIDE สำหรับมือใหม่
# ========================================
# คู่มือครบถ้วน: ตั้งแต่เช่า GPU จนถึงเริ่มสตรีม
# สำหรับ RunPod 96GB VRAM RTX Pro

---

## 📋 สารบัญ
1. [ขั้นตอนที่ 1: เช่า GPU บน RunPod](#ขั้นตอนที่-1-เช่า-gpu-บน-runpod)
2. [ขั้นตอนที่ 2: เข้าไปในเครื่อง GPU](#ขั้นตอนที่-2-เข้าไปในเครื่อง-gpu)
3. [ขั้นตอนที่ 3: ติดตั้ง World Engine](#ขั้นตอนที่-3-ติดตั้ง-world-engine)
4. [ขั้นตอนที่ 4: ตั้งค่า YouTube](#ขั้นตอนที่-4-ตั้งค่า-youtube)
5. [ขั้นตอนที่ 5: เริ่มสตรีม](#ขั้นตอนที่-5-เริ่มสตรีม)
6. [บัญชีคำสั่งอ้างอิง](#บัญชีคำสั่งอ้างอิง)

---

## ขั้นตอนที่ 1: เช่า GPU บน RunPod

### 1.1 สมัครสมาชิก RunPod
- ไปที่ https://www.runpod.io/
- กดปุ่ม "Sign Up" และสร้างบัญชี
- เติมเงินลงในบัญชี (ใช้บัตรเครดิต/PayPal)

### 1.2 เลือก GPU Template
- ไปที่ **Pods** → **Browse**
- ค้นหา **"PyTorch 2.4.0 CUDA 12.4"** หรือ **"Pytorch 2.4"**
- ให้แน่ใจว่ามี **RTX Pro 6000 (96GB)** ให้เลือก

### 1.3 เริ่มต้น Pod
- กดปุ่ม **"Start"** ที่ pod ที่คุณเลือก
- รอให้เครื่องเปิดขึ้น (~1-2 นาที)
- คุณจะเห็นหน้าจอ terminal/console

### 1.4 เข้าสู่เครื่อง
หลังจากเครื่อง Pod เปิดแล้ว คุณจะเห็น URL ของ pod
- คลิก **"Connect"** หรือ **"Connect via SSH"**
- หรือใช้ **Web Terminal** โดยตรง

---

## ขั้นตอนที่ 2: เข้าไปในเครื่อง GPU

### 2.1 ถ้าใช้ Web Terminal (ง่ายที่สุด)
- RunPod จะให้ terminal ขึ้นมา ให้พิมพ์คำสั่งต่อไปตรงนี้เลย

### 2.2 ถ้าใช้ SSH (สำหรับเครื่องคอมพิวเตอร์ของคุณ)
```bash
# RunPod จะให้ SSH command มา ให้ copy และ paste ลงใน terminal ของคุณ
# ตัวอย่าง:
ssh -i runpod_key.pem user@1.2.3.4 -p 12345
```

---

## ขั้นตอนที่ 3: ติดตั้ง World Engine

### 3.1 อัพเดตระบบ (ใช้เวลา 2-3 นาที)
```bash
apt-get update && apt-get upgrade -y
```

### 3.2 ดาวน์โหลด Installation Script
```bash
# เข้าไปยังโฮมไดเรกทอรี่
cd /root

# ดาวน์โหลด installation script จาก GitHub
wget https://raw.githubusercontent.com/guyboymusic-sys/world-engine/initial-setup/scripts/runpod_install_96gb.sh

# ให้สิทธิ์ในการรัน
chmod +x runpod_install_96gb.sh
```

### 3.3 รัน Installation Script (⏱️ ใช้เวลาประมาณ 30-45 นาที)
```bash
# เริ่มการติดตั้งอัตโนมัติ
bash runpod_install_96gb.sh
```

**สิ่งที่ script จะทำ:**
✅ ติดตั้ง Python dependencies  
✅ ดาวน์โหลด AI models (SkyReels V2, AudioLDM2, Tortoise TTS, Mistral 7B)  
✅ ตั้งค่า PostgreSQL Database  
✅ ตั้งค่า Redis Cache  
✅ สร้าง Docker containers ทั้งหมด  
✅ เริ่มบริการทั้งหมด  

**ไม่ต้องทำอะไรระหว่างการติดตั้ง เพียงแค่รอและดูตัวเลขเพิ่มขึ้น!**

### 3.4 ตรวจสอบว่าติดตั้งสำเร็จ
```bash
# สถานะของ services
cd /root/world-engine && ./status.sh

# ควรเห็นผลลัพธ์:
# ✓ Backend API (8000) - UP
# ✓ PostgreSQL (5432) - UP
# ✓ Redis (6379) - UP
# ✓ SkyReels V2 (8002) - UP
# ✓ AudioLDM2 (8003) - UP
# ✓ Tortoise TTS (8001) - UP
# ✓ Ollama (11434) - UP
```

---

## ขั้นตอนที่ 4: ตั้งค่า YouTube

### 4.1 ได้รับ YouTube API Key

#### ขั้นตอน A: เปิด Google Cloud Console
- ไปที่ https://console.cloud.google.com/
- กดปุ่ม **"Create Project"**
- ตั้งชื่อ: **"World Engine"** → กด **Create**

#### ขั้นตอน B: เปิด YouTube API
- ไปที่ **APIs & Services** → **Library**
- ค้นหา **"YouTube Data API v3"**
- กดปุ่ม **"Enable"**

#### ขั้นตอน C: สร้าง API Key
- ไปที่ **APIs & Services** → **Credentials**
- กดปุ่ม **"Create Credentials"** → เลือก **"API Key"**
- Copy API Key (แบบนี้: `AIzaSyD...`)

### 4.2 ได้รับ Channel ID
- ไปที่ YouTube channel ของคุณ
- กดปุ่ม **"About"** (แท็บที่ 3)
- ดูหมายเลข "@channelname" หรือ "Channel ID: UC..."
- Copy Channel ID (แบบนี้: `UC123456789...`)

### 4.3 ตั้งค่า Environment File

```bash
# เปิดไฟล์ .env เพื่อแก้ไข
nano /root/world-engine/.env
```

**ค้นหาและแก้ไขบรรทัดนี้:**

```env
# ❌ BEFORE (ปล่อยไว้เช่นนี้)
YOUTUBE_CHANNEL_ID=your_channel_id_here
YOUTUBE_API_KEY=your_api_key_here
STREAM_NAME=your_stream_name_here

# ✅ AFTER (แทนที่ด้วยค่าของคุณ)
YOUTUBE_CHANNEL_ID=UC123456789abcdefghijklmnop
YOUTUBE_API_KEY=AIzaSyD1234567890abcdefghijklmnop
STREAM_NAME=World Engine Gaming Stream
```

**วิธีแก้ไขใน nano:**
1. ใช้ **Ctrl+X** เพื่อค้นหา
2. พิมพ์ `YOUTUBE_CHANNEL_ID`
3. ลบข้อความเก่า (ใช้ **Delete** หรือ **Backspace**)
4. พิมพ์ Channel ID ของคุณ
5. กด **Ctrl+X** → **y** → **Enter** เพื่อบันทึก

### 4.4 Reload Services
```bash
cd /root/world-engine && ./reload.sh
```

---

## ขั้นตอนที่ 5: เริ่มสตรีม

### 5.1 ตรวจสอบทุกอย่างพร้อม
```bash
cd /root/world-engine && ./status.sh
```

ควรเห็น:
```
✓ All services running
✓ Database connected
✓ Redis connected
✓ GPU status: OK
```

### 5.2 ดูประวัติการทำงาน (Logs)
```bash
cd /root/world-engine && ./logs.sh
```

ปด Logs ได้โดยกด **Ctrl+C**

### 5.3 ตรวจสอบการใช้ GPU
```bash
# ตรวจสอบ GPU usage แบบ real-time
watch -n 1 nvidia-smi

# หรือใช้ helper script
cd /root/world-engine && ./monitor_gpu.sh
```

### 5.4 เริ่มสตรีม!
```bash
# เปิด terminal ใหม่ (ยังคงอยู่ใน SSH)
# Terminal 1: Backend logs
cd /root/world-engine && ./logs.sh

# Terminal 2: เรียก API เพื่อเริ่มสตรีม
curl -X POST http://localhost:8000/api/stream/start \
  -H "Content-Type: application/json" \
  -d '{
    "channel_id": "UC123456789...",
    "title": "First World Engine Stream!",
    "description": "Testing AI-generated streaming"
  }'
```

**สตรีมควรจะเริ่มขึ้น!** ✅

---

## 📱 บัญชีคำสั่งอ้างอิง

### 🚀 การเริ่มต้น
```bash
# 1. เข้าไปยังโปรเจกต์
cd /root/world-engine

# 2. เริ่มบริการทั้งหมด
./start.sh

# 3. รอประมาณ 30 วินาที แล้วตรวจสอบ
./status.sh
```

### 🔧 การจัดการบริการ
```bash
# ดูสถานะทั้งหมด
./status.sh

# ดูประวัติการทำงาน
./logs.sh

# รีโหลดบริการ (ถ้ามีปัญหา)
./reload.sh

# หยุดบริการทั้งหมด
./stop.sh
```

### 📊 การตรวจสอบ GPU
```bash
# ดู GPU usage แบบ real-time
./monitor_gpu.sh

# ดูเฉพาะ CUDA info
nvidia-smi
```

### 🌐 API Endpoints
```bash
# ตรวจสอบ Backend
curl http://localhost:8000/health

# ดูเอกสาร API (เปิดในเบราว์เซอร์)
http://localhost:8000/docs

# Ollama API
curl http://localhost:11434/api/tags

# SkyReels V2 API
curl http://localhost:8002/health

# AudioLDM2 API
curl http://localhost:8003/health

# Tortoise TTS API
curl http://localhost:8001/health
```

### 📝 การแก้ไขการตั้งค่า
```bash
# แก้ไข .env
nano /root/world-engine/.env

# แก้ไขแล้วบันทึก (Ctrl+X → y → Enter)
# แล้ว reload services
./reload.sh
```

### 🐛 การ Debug
```bash
# ดูตัวบันทึก backend แค่บรรทัดล่าสุด
tail -f /root/world-engine/logs/backend.log

# ดูลอกเข้า Docker container
docker logs world-engine-backend -f

# เข้า database
docker exec -it world-engine-db psql -U postgres -d world_engine
```

---

## 🎬 ขั้นตอนการสตรีมทีละขั้น

### ขั้นตอนที่ 1: เตรียม
```bash
cd /root/world-engine

# ตรวจสอบบริการ
./status.sh

# ดูประวัติการทำงาน
./logs.sh
```

### ขั้นตอนที่ 2: ส่งคำสั่งเริ่มสตรีม
```bash
# Terminal ใหม่
curl -X POST http://localhost:8000/api/stream/start \
  -H "Content-Type: application/json" \
  -d '{
    "channel_id": "YOUR_CHANNEL_ID",
    "title": "World Engine Live Stream",
    "description": "AI-powered interactive streaming"
  }'
```

### ขั้นตอนที่ 3: ดูสตรีม
- ไปที่ YouTube channel ของคุณ
- คลิก "Go Live" หรือดูที่ https://youtube.com/watch?v=YOUR_BROADCAST_ID

### ขั้นตอนที่ 4: ส่งคำสั่งต่างๆ ให้ AI
```bash
# ตัวอย่าง: สั่งให้ character ลง craft
curl -X POST http://localhost:8000/api/action \
  -H "Content-Type: application/json" \
  -d '{
    "action": "craft",
    "item": "sword",
    "character_id": "main_character"
  }'

# ตัวอย่าง: การเดินเข้าป่า
curl -X POST http://localhost:8000/api/action \
  -H "Content-Type: application/json" \
  -d '{
    "action": "move",
    "location": "forest",
    "character_id": "main_character"
  }'
```

### ขั้นตอนที่ 5: หยุดสตรีม
```bash
curl -X POST http://localhost:8000/api/stream/stop
```

---

## ⚠️ ข้อปัญหาทั่วไปและการแก้ไข

### ปัญหา: Services ไม่ขึ้น
```bash
# ลองรีโหลด
./reload.sh

# รอ 30 วินาที แล้วตรวจสอบ
./status.sh
```

### ปัญหา: GPU ใช้ไม่ได้
```bash
# ตรวจสอบ CUDA
nvidia-smi

# ตรวจสอบ Docker GPU
docker run --rm --gpus all nvidia/cuda:12.4.1-runtime-ubuntu22.04 nvidia-smi
```

### ปัญหา: YouTube API ไม่ทำงาน
```bash
# ตรวจสอบ credentials ใน .env
cat /root/world-engine/.env | grep YOUTUBE

# ตรวจสอบให้แน่ใจว่า:
# ✓ YOUTUBE_CHANNEL_ID ถูกต้อง
# ✓ YOUTUBE_API_KEY ถูกต้อง
# ✓ ไม่มี space หรือ quotes เพิ่มเติม
```

### ปัญหา: Models ไม่ได้ดาวน์โหลด
```bash
# ตรวจสอบพื้นที่ว่าง
df -h

# ดูว่า models อยู่ไหน
ls -lh /root/world-engine/models/

# ดาวน์โหลด models เพิ่มเติมด้วยตัวเอง
cd /root/world-engine
python3 -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='SkyworkAI/SkyReels-V2-14B', filename='pytorch_model.bin', local_dir='./models/skyreels')"
```

---

## 📊 ตัวอย่าง CURL Commands

### ตัวอย่าง 1: เช็คสถานะ
```bash
curl http://localhost:8000/health
# ผลลัพธ์: {"status": "ok"}
```

### ตัวอย่าง 2: สร้าง Character
```bash
curl -X POST http://localhost:8000/api/characters/create \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Hero",
    "appearance": "tall adventurer with sword"
  }'
```

### ตัวอย่าง 3: สั่งสร้างวิดีโอ
```bash
curl -X POST http://localhost:8000/api/generate/video \
  -H "Content-Type: application/json" \
  -d '{
    "character_id": "hero_1",
    "action": "walking through forest",
    "duration": 30
  }'
```

### ตัวอย่าง 4: สั่งสร้างเสียง
```bash
curl -X POST http://localhost:8000/api/generate/audio \
  -H "Content-Type: application/json" \
  -d '{
    "type": "dialogue",
    "text": "Hello, welcome to my world!",
    "voice": "character_voice_1"
  }'
```

---

## ✅ Checklist สำหรับการเริ่มต้นแรก

- [ ] เช่า GPU บน RunPod (96GB)
- [ ] เข้า Terminal/SSH ของ RunPod
- [ ] รัน `bash runpod_install_96gb.sh`
- [ ] รอการติดตั้งเสร็จ (~45 นาที)
- [ ] ได้รับ YouTube API Key
- [ ] ได้รับ YouTube Channel ID
- [ ] แก้ไข `.env` ด้วย credentials
- [ ] รัน `./reload.sh`
- [ ] รัน `./status.sh` (ตรวจสอบทุกบริการ)
- [ ] ส่ง curl command เพื่อเริ่มสตรีม
- [ ] ดูสตรีมบน YouTube

---

## 🆘 ต้องการความช่วยเหลือเพิ่มเติม?

```bash
# ดู logs ที่ละเอียด
cd /root/world-engine && ./logs.sh

# ดู status ทั้งหมด
./status.sh

# ตรวจสอบ configs
cat /root/world-engine/.env

# ดูการใช้ VRAM
nvidia-smi

# ตรวจสอบ database
docker exec -it world-engine-db psql -U postgres -d world_engine -c "SELECT * FROM characters;"
```

---

**🎉 ยินดีต้อนรับสู่ World Engine! ขอให้สตรีมของคุณสำเร็จ! 🎉**

