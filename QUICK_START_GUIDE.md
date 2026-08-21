# 🎮 World Engine - QUICK START GUIDE สำหรับมือใหม่
# ========================================
# คู่มือครบถ้วน: ตั้งแต่เช่า GPU จนถึงเริ่มสตรีมบน YouTube Live
# สำหรับ RunPod 96GB VRAM RTX Pro

---

## 📋 สารบัญ
1. [ขั้นตอนที่ 1: เช่า GPU บน RunPod](#ขั้นตอนที่-1-เช่า-gpu-บน-runpod)
2. [ขั้นตอนที่ 2: เข้าไปในเครื่อง GPU](#ขั้นตอนที่-2-เข้าไปในเครื่อง-gpu)
3. [ขั้นตอนที่ 3: ติดตั้ง World Engine](#ขั้นตอนที่-3-ติดตั้ง-world-engine)
4. [ขั้นตอนที่ 4: ได้รับ YouTube Stream Key](#ขั้นตอนที่-4-ได้รับ-youtube-stream-key)
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
✅ ติดตั้ง FFmpeg สำหรับ streaming  
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
# ✓ FFmpeg Streaming - UP
```

---

## ขั้นตอนที่ 4: ได้รับ YouTube Stream Key

### ⚠️ สำคัญ: YouTube Stream Key คืออะไร?
YouTube Stream Key (หรือ RTMP Key) คือรหัสลับที่ใช้สำหรับเชื่อมต่อการสตรีมจากเครื่องของคุณ (RunPod) ไปยัง YouTube Live

### 4.1 ไปที่ YouTube Studio
- ไปที่ https://studio.youtube.com/
- เข้าด้วยบัญชี YouTube ของคุณ

### 4.2 เปิด "Go Live" (เพื่อรับ Stream Key)
- ที่เมนูด้านซ้าย คลิก **"Go live"** (หรือ "Create" → "Go live")
- เลือก **"Set up stream"** → **"RTMP encoder"** (ไม่ใช่ "Webcam")

### 4.3 คัดลอก Stream Key
บนหน้า RTMP encoder คุณจะเห็น:

```
Server URL (RTMP): rtmps://a.rtmp.youtube.com/live2/
Stream key (or Stream name): abc1-2345-67890-abcd
```

**นี่คือสิ่งที่เราต้องการ:**
- **Server URL**: `rtmps://a.rtmp.youtube.com/live2/`
- **Stream Key**: `abc1-2345-67890-abcd` (ของคุณจะต่างกัน)

### 4.4 เก็บลิงค์ RTMP ที่สมบูรณ์
```
rtmps://a.rtmp.youtube.com/live2/abc1-2345-67890-abcd
```

> **⚠️ สำคัญ:** อย่าแชร์ Stream Key กับใครเด็ดขาด! มันคือรหัสของคุณเท่านั้น!

### 4.5 ตั้งค่า .env ใน RunPod

```bash
# เปิดไฟล์ .env เพื่อแก้ไข
nano /root/world-engine/.env
```

**ค้นหาและแก้ไขบรรทัดนี้:**

```env
# ❌ BEFORE (ปล่อยไว้เช่นนี้)
RTMP_SERVER_URL=rtmps://a.rtmp.youtube.com/live2/
RTMP_STREAM_KEY=your_stream_key_here
STREAM_TITLE=your_stream_title_here

# ✅ AFTER (แทนที่ด้วยค่าของคุณ)
RTMP_SERVER_URL=rtmps://a.rtmp.youtube.com/live2/
RTMP_STREAM_KEY=abc1-2345-67890-abcd
STREAM_TITLE=World Engine AI Gaming Stream
```

**วิธีแก้ไขใน nano:**
1. ใช้ **Ctrl+W** เพื่อค้นหา
2. พิมพ์ `RTMP_STREAM_KEY`
3. ลบข้อความเก่า (ใช้ **Delete** หรือ **Backspace**)
4. พิมพ์ Stream Key ของคุณ (ตัวอย่าง: `abc1-2345-67890-abcd`)
5. กด **Ctrl+X** → **y** → **Enter** เพื่อบันทึก

### 4.6 Reload Services
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
✓ FFmpeg ready for streaming
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

### 5.4 เริ่มสตรีมไปยัง YouTube! 🎬
```bash
# เรียก API เพื่อเริ่มสตรีมด้วย RTMP
curl -X POST http://localhost:8000/api/stream/start \
  -H "Content-Type: application/json" \
  -d '{
    "title": "World Engine AI Gaming Stream",
    "description": "First AI-powered interactive stream!"
  }'
```

**ผลลัพธ์ที่ควรได้:**
```json
{
  "status": "streaming",
  "stream_id": "abc123",
  "rtmp_connected": true,
  "gpu_usage": "78%",
  "message": "Stream started successfully!"
}
```

### 5.5 ตรวจสอบสตรีมบน YouTube
- ไปที่ https://studio.youtube.com/
- ควรเห็นสตรีมกำลังทำงาน (ไฟเขียว/LIVE)
- ไปที่ YouTube channel ของคุณเพื่อดูสตรีม

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

### 📺 การใช้ RTMP Streaming
```bash
# เริ่มสตรีมไปยัง YouTube
curl -X POST http://localhost:8000/api/stream/start \
  -H "Content-Type: application/json" \
  -d '{"title": "My Stream Title"}'

# ดูสถานะสตรีม
curl http://localhost:8000/api/stream/status

# หยุดสตรีม
curl -X POST http://localhost:8000/api/stream/stop

# ดึงข้อมูลสตรีม
curl http://localhost:8000/api/stream/info
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

# รีสตาร์ทบริการ
./restart.sh
```

### 📊 การตรวจสอบ GPU และ Streaming
```bash
# ดู GPU usage แบบ real-time
./monitor_gpu.sh

# ดูเฉพาะ CUDA info
nvidia-smi

# ตรวจสอบ FFmpeg process
ps aux | grep ffmpeg

# ดู RTMP connection status
netstat -tlnp | grep ffmpeg
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

### 📝 การแก้ไขการตั้งค่า RTMP
```bash
# แก้ไข .env
nano /root/world-engine/.env

# ค้นหา: RTMP_STREAM_KEY
# แทนที่ด้วย stream key ของคุณ

# บันทึก (Ctrl+X → y → Enter)
# แล้ว reload services
./reload.sh
```

### 🐛 การ Debug Streaming
```bash
# ดูตัวบันทึก FFmpeg
tail -f /root/world-engine/logs/ffmpeg.log

# ดูตัวบันทึก streaming backend
tail -f /root/world-engine/logs/stream.log

# ตรวจสอบ RTMP connection
curl -v rtmps://a.rtmp.youtube.com/live2/abc1-2345-67890-abcd

# ดู CPU/Memory usage
top -b -n 1 | head -20
```

---

## 🎬 ขั้นตอนการสตรีมทีละขั้น (เต็มรูป)

### ขั้นตอนที่ 1: เตรียมก่อนสตรีม
```bash
cd /root/world-engine

# 1. ตรวจสอบบริการ
./status.sh

# 2. ดูประวัติการทำงาน (ให้เห็นว่ามีข้อผิดพลาดไหม)
./logs.sh

# 3. ตรวจสอบการใช้ GPU
nvidia-smi
```

### ขั้นตอนที่ 2: ไปที่ YouTube Studio
- เข้าไปที่ https://studio.youtube.com/
- คลิก "Go live" → "Set up stream"
- ตรวจสอบ Stream Key (ควรตรงกับที่ใน .env)

### ขั้นตอนที่ 3: เริ่มสตรีมด้วยคำสั่ง
```bash
# Terminal 1: ดูประวัติการทำงาน
cd /root/world-engine && ./logs.sh

# Terminal 2: เริ่มสตรีม
curl -X POST http://localhost:8000/api/stream/start \
  -H "Content-Type: application/json" \
  -d '{
    "title": "World Engine AI Gaming Stream",
    "description": "Live AI-powered gaming with SkyReels V2!"
  }'
```

### ขั้นตอนที่ 4: ดูผลลัพธ์
```bash
# ควรเห็น:
{
  "status": "streaming",
  "stream_id": "abc123xyz",
  "rtmp_connected": true,
  "bitrate": "6000k",
  "fps": 30,
  "gpu_usage": "85%"
}
```

### ขั้นตอนที่ 5: ตรวจสอบบน YouTube
- ไปที่ YouTube Live Control Room
- ควรเห็นตัวอักษร "LIVE" แสดง (สีแดง)
- ดูสตรีมบน YouTube channel: `https://youtube.com/@YourChannelName/live`

### ขั้นตอนที่ 6: ส่งคำสั่งให้ AI
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

# ตัวอย่าง: สั่งให้พูด
curl -X POST http://localhost:8000/api/action \
  -H "Content-Type: application/json" \
  -d '{
    "action": "speak",
    "text": "Hello everyone! Welcome to World Engine!",
    "character_id": "main_character"
  }'
```

### ขั้นตอนที่ 7: หยุดสตรีม
```bash
# ส่งคำสั่งหยุด
curl -X POST http://localhost:8000/api/stream/stop

# ควรเห็น:
{
  "status": "stopped",
  "duration": "1 hour 23 minutes",
  "total_frames": "150000",
  "message": "Stream ended gracefully"
}
```

---

## ⚠️ ข้อปัญหาทั่วไปและการแก้ไข

### ❌ ปัญหา: "RTMP connection failed"
```bash
# 1. ตรวจสอบ Stream Key
cat /root/world-engine/.env | grep RTMP

# 2. ให้แน่ใจว่า:
# ✓ Stream Key ไม่มี spaces
# ✓ Server URL ถูกต้อง (rtmps://a.rtmp.youtube.com/live2/)
# ✓ ไฟเวลล์ไม่บล็อก port 443/1935

# 3. ลองตั้งค่าใหม่
nano /root/world-engine/.env
# แล้ว reload
./reload.sh
```

### ❌ ปัญหา: "Stream key is invalid"
```bash
# Stream key หมดอายุ ให้ไปที่ YouTube สร้างใหม่:
# 1. YouTube Studio → Go live → Set up stream
# 2. Copy Stream key ใหม่
# 3. อัพเดต .env
nano /root/world-engine/.env
# แล้วค้นหา RTMP_STREAM_KEY และแทนที่
./reload.sh
```

### ❌ ปัญหา: Services ไม่ขึ้น
```bash
# ลองรีโหลด
./reload.sh

# รอ 30 วินาที แล้วตรวจสอบ
./status.sh

# ถ้ายังไม่ได้ ลอง restart
./restart.sh
```

### ❌ ปัญหา: GPU ใช้ไม่ได้
```bash
# ตรวจสอบ CUDA
nvidia-smi

# ตรวจสอบ Docker GPU
docker run --rm --gpus all nvidia/cuda:12.4.1-runtime-ubuntu22.04 nvidia-smi
```

### ❌ ปัญหา: FFmpeg ไม่เชื่อมต่อ YouTube
```bash
# ตรวจสอบว่า FFmpeg ติดตั้งแล้ว
which ffmpeg

# ดู FFmpeg logs
tail -f /root/world-engine/logs/ffmpeg.log

# ลองเชื่อมต่อด้วยตนเอง (เพื่อ test)
ffmpeg -f gdigrab -i desktop -vcodec libx264 -preset ultrafast \
  -pix_fmt yuv420p -f flv rtmps://a.rtmp.youtube.com/live2/YOUR_STREAM_KEY
```

### ❌ ปัญหา: GPU memory ไม่เพียงพอ
```bash
# ดู GPU memory usage
nvidia-smi

# ลด quality หรือ resolution
nano /root/world-engine/.env
# ค้นหา: VIDEO_BITRATE (ลดจาก 6000k เป็น 4000k)
# ค้นหา: VIDEO_RESOLUTION (ลดจาก 1080p เป็น 720p)
./reload.sh
```

---

## 📊 ตัวอย่าง CURL Commands สำหรับการสตรีม

### ตัวอย่าง 1: เช็คสถานะ
```bash
curl http://localhost:8000/health
# ผลลัพธ์: {"status": "ok", "gpu": "active"}
```

### ตัวอย่าง 2: เริ่มสตรีม
```bash
curl -X POST http://localhost:8000/api/stream/start \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My AI Gaming Stream",
    "description": "Powered by World Engine"
  }'
```

### ตัวอย่าง 3: ดูสถานะการสตรีม
```bash
curl http://localhost:8000/api/stream/status
# ผลลัพธ์:
# {
#   "is_streaming": true,
#   "fps": 30,
#   "bitrate": "6000k",
#   "gpu_usage": "82%",
#   "uptime": "1 hour 15 minutes"
# }
```

### ตัวอย่าง 4: สั่งให้ AI ทำสิ่งต่างๆ
```bash
curl -X POST http://localhost:8000/api/action \
  -H "Content-Type: application/json" \
  -d '{
    "action": "generate_video",
    "prompt": "A hero walking through a magical forest",
    "duration": 30
  }'
```

### ตัวอย่าง 5: หยุดสตรีม
```bash
curl -X POST http://localhost:8000/api/stream/stop
```

---

## ✅ Checklist สำหรับการเริ่มต้นแรก

- [ ] เช่า GPU บน RunPod (96GB RTX Pro)
- [ ] เข้า Terminal/SSH ของ RunPod
- [ ] รัน `bash runpod_install_96gb.sh`
- [ ] รอการติดตั้งเสร็จ (~45 นาที)
- [ ] ไปที่ YouTube Studio
- [ ] คลิก "Go live" → "Set up stream" → "RTMP encoder"
- [ ] Copy Stream Key จาก YouTube
- [ ] แก้ไข `.env` ด้วย RTMP Stream Key
- [ ] รัน `./reload.sh`
- [ ] รัน `./status.sh` (ตรวจสอบทุกบริการ)
- [ ] ส่ง curl command เพื่อเริ่มสตรีม
- [ ] ตรวจสอบบน YouTube ว่าสตรีมออนไลน์แล้ว
- [ ] ส่งคำสั่ง API เพื่อควบคุม AI

---

## 🆘 ต้องการความช่วยเหลือเพิ่มเติม?

```bash
# ดู logs ที่ละเอียด
cd /root/world-engine && ./logs.sh

# ดู status ทั้งหมด
./status.sh

# ตรวจสอบ RTMP configs
cat /root/world-engine/.env | grep RTMP

# ดูการใช้ VRAM
nvidia-smi

# ตรวจสอบ FFmpeg process
ps aux | grep ffmpeg

# ดู RTMP connection
netstat -tlnp | grep 1935
```

---

## 🎯 Quick Reference: YouTube RTMP

| คำศัพท์ | ความหมาย | ตัวอย่าง |
|--------|---------|--------|
| **RTMP** | Real-Time Messaging Protocol | ใช้สำหรับส่งวิดีโอแบบ live |
| **Stream Key** | รหัสลับสำหรับเชื่อมต่อ | `abc1-2345-67890-abcd` |
| **Server URL** | ที่อยู่ของ YouTube server | `rtmps://a.rtmp.youtube.com/live2/` |
| **RTMP URL** | Full URL สำหรับ streaming | `rtmps://a.rtmp.youtube.com/live2/abc1-2345...` |

---

**🎉 ยินดีต้อนรับสู่ World Engine! ขอให้สตรีมของคุณสำเร็จ! 🎉**

อย่าลืม:
- ✅ **ป้องกัน Stream Key** - อย่าแชร์กับใคร!
- ✅ **ตรวจสอบ GPU usage** - อย่าให้ VRAM เต็ม
- ✅ **ดู logs** - ถ้ามีปัญหาให้ดูที่นี่ก่อน
- ✅ **วอร์มอัพเครื่อง** - รอให้ services พร้อมก่อนเริ่มสตรีม
