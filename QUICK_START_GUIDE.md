# 🌍 World Engine – คู่มือเริ่มต้นฉบับย่อ
> **สำหรับผู้เริ่มต้นด้าน AI** · ใช้เวลาอ่านประมาณ 10 นาที

---

## ระบบคืออะไร? (ภาพรวม)

World Engine คือระบบที่ทำให้ YouTube Live ของคุณ "มีชีวิต" โดยอัตโนมัติ:

```
ผู้ดูบริจาค (Super Chat)
        │
        ▼
🤖 Mistral 7B  →  สร้างเรื่องราวในเกม
🎵 AudioLDM2   →  สร้างเสียงบรรยากาศ
🗣️ Tortoise    →  พากย์เสียงตัวละคร
🎬 SkyReels V2 →  สร้างวิดีโอ
        │
        ▼
🔀 FFmpeg รวมวิดีโอ + เสียง
        │
        ▼
📡 ส่งตรงไป YouTube ผ่าน RTMP
```

เมื่อไม่มีคนบริจาค ระบบ **Idle Level** จะสร้างเนื้อหาอัตโนมัติ  
(ระดับ 1 = สงบ → ระดับ 10 = หายนะ!)

---

## สิ่งที่ต้องมีก่อน

| สิ่งที่ต้องการ | รายละเอียด |
|---|---|
| **Linux** (Ubuntu 22.04 แนะนำ) | Windows ใช้ WSL2 ได้ |
| **NVIDIA GPU** ≥ 16 GB VRAM | RTX 3090 / 4090 / A100 ฯลฯ |
| **CUDA 12.1+** | ติดตั้งจาก [nvidia.com](https://developer.nvidia.com/cuda-downloads) |
| **Docker + Docker Compose v2** | `sudo apt install docker.io docker-compose-plugin` |
| **nvidia-container-toolkit** | ดูขั้นตอนด้านล่าง |
| **พื้นที่ว่าง ≥ 100 GB** | สำหรับโมเดล AI |
| **Python 3.11+** | `sudo apt install python3.11 python3.11-venv` |
| **FFmpeg** | `sudo apt install ffmpeg` |

### ติดตั้ง nvidia-container-toolkit (ครั้งเดียว)
```bash
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

---

## ขั้นตอนติดตั้ง (ทีละขั้น)

### ขั้น 1 – โคลนโปรเจกต์

```bash
git clone https://github.com/guyboymusic-sys/world-engine.git
cd world-engine
```

### ขั้น 2 – ตั้งค่าไฟล์ .env

```bash
cp backend/.env.example backend/.env
nano backend/.env   # หรือใช้ editor ที่ชอบ
```

**ค่าที่ต้องแก้ไข:**

```dotenv
SECRET_KEY=ใส่ข้อความสุ่มยาวๆ ที่นี่

# Stream key จาก YouTube Studio → Live → ตั้งค่าสตรีม
YOUTUBE_STREAM_KEY=xxxx-xxxx-xxxx-xxxx

# API key จาก Google Cloud Console (เปิดใช้ YouTube Data API v3)
YOUTUBE_API_KEY=AIza...

# Live Chat ID (ดูได้จาก API หรือ URL ของ broadcast)
YOUTUBE_LIVE_CHAT_ID=...
```

> 💡 **หาก YouTube STREAM_KEY ว่าง** ระบบจะส่งไปที่ nginx-rtmp ภายในแทน (สำหรับทดสอบ)

### ขั้น 3 – รัน Setup (ดาวน์โหลดโมเดลทั้งหมด)

```bash
bash scripts/setup.sh
```

⏳ **ใช้เวลาประมาณ 1–3 ชั่วโมง** ขึ้นอยู่กับความเร็วอินเทอร์เน็ต  
โมเดลที่ดาวน์โหลด (~70 GB รวม):
- SkyReels V2 (~28 GB)
- AudioLDM2 (~5 GB)
- Tortoise TTS (~8 GB)
- Mistral 7B (~14 GB)

### ขั้น 4 – เปิดใช้งานทั้งระบบ

```bash
docker compose up -d
```

ตรวจสอบว่าทุกอย่างทำงาน:
```bash
docker compose ps
```

ผลที่ควรได้ (ทุกรายการ `State = Up`):
```
NAME                STATE    PORTS
api                 Up       0.0.0.0:8000->8000/tcp
beat                Up
db                  Up       0.0.0.0:5432->5432/tcp
flower              Up       0.0.0.0:5555->5555/tcp
nginx-rtmp          Up       0.0.0.0:1935->1935/tcp
redis               Up       0.0.0.0:6379->6379/tcp
worker-audio        Up
worker-chat-idle    Up
worker-composite    Up
worker-llm          Up
worker-tts          Up
worker-video        Up
```

---

## วิธีใช้งาน (ขั้นตอนสตรีม)

### ขั้นตอนที่ 1 – สร้างวิดีโอตัวอย่าง

เปิด Swagger UI: **http://localhost:8000/docs**

หรือใช้ curl:
```bash
curl -X POST http://localhost:8000/api/v1/video/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "a dragon flying over a volcano at sunset", "duration_seconds": 5}'
```

บันทึก `id` ที่ได้มา แล้วตรวจสอบสถานะ:
```bash
curl http://localhost:8000/api/v1/video/{id}
```

รอจน `status` เป็น `"success"` แล้วบันทึก `result_path`

### ขั้นตอนที่ 2 – สร้างเสียง

```bash
curl -X POST http://localhost:8000/api/v1/audio/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "epic orchestral battle music", "duration_seconds": 10}'
```

รอจน `status = "success"` แล้วบันทึก `result_path`

### ขั้นตอนที่ 3 – รวมวิดีโอ + เสียง

```bash
curl -X POST http://localhost:8000/api/v1/composite/build \
  -H "Content-Type: application/json" \
  -d '{
    "video_path": "/outputs/video/xxx.mp4",
    "audio_path": "/outputs/audio/yyy.wav"
  }'
```

รอจน `status = "success"` (ไฟล์จะถูกบันทึกเป็น `/outputs/stream_input.mp4`)

### ขั้นตอนที่ 4 – เริ่มสตรีม

```bash
curl -X POST http://localhost:8000/api/v1/stream/start
```

ตรวจสอบสถานะ:
```bash
curl http://localhost:8000/api/v1/stream/status
# {"streaming": true}
```

### หยุดสตรีม

```bash
curl -X POST http://localhost:8000/api/v1/stream/stop
```

---

## หน้า Monitoring

| URL | ประโยชน์ |
|---|---|
| http://localhost:8000/docs | Swagger UI – ทดสอบ API ทั้งหมด |
| http://localhost:5555 | Flower – ดู Celery workers และคิวงาน |

---

## ระบบ Idle Level (อัตโนมัติ)

ระบบนี้ทำงานอัตโนมัติ **ไม่ต้องตั้งค่าอะไรเพิ่ม**

- ทุก 30 วินาที ระบบจะตรวจสอบว่ามีบริจาคหรือไม่
- ถ้าไม่มีบริจาคนาน > `IDLE_TRIGGER_SECONDS` (ค่าเริ่มต้น 2 นาที)
  → สร้างเนื้อหาอัตโนมัติ + เพิ่ม level
- เมื่อมีคนบริจาค → level รีเซ็ตกลับเป็น 1

ปรับเวลาใน `.env`:
```dotenv
IDLE_TRIGGER_SECONDS=120   # 120 วินาที = 2 นาที
```

---

## YouTube Chat Polling (รับบริจาคอัตโนมัติ)

ระบบจะ poll YouTube Live Chat API ทุก 15 วินาที และ  
ส่ง SuperChat ไปยัง `/api/v1/donations` โดยอัตโนมัติ

**ต้องตั้งค่า:**
```dotenv
YOUTUBE_API_KEY=AIza...
YOUTUBE_LIVE_CHAT_ID=...
```

**วิธีหา Live Chat ID:**
1. เข้า [YouTube Live Dashboard](https://studio.youtube.com/channel/CHANNEL_ID/livestreaming/dashboard)
2. เปิด broadcast แล้วดู URL – มี `?v=VIDEO_ID`
3. เรียก YouTube API: `GET https://www.googleapis.com/youtube/v3/videos?part=liveStreamingDetails&id=VIDEO_ID&key=YOUR_KEY`
4. คัดลอก `liveStreamingDetails.activeLiveChatId`

---

## แก้ปัญหาเบื้องต้น

### ❌ GPU ไม่เจอ
```bash
nvidia-smi   # ควรแสดง GPU ของคุณ
docker run --rm --gpus all nvidia/cuda:12.1.1-base-ubuntu22.04 nvidia-smi
```
ถ้าไม่ได้ → ตรวจสอบ nvidia-container-toolkit อีกครั้ง

### ❌ `FFmpeg failed to start` เมื่อ Start Stream
ต้องสร้าง `/outputs/stream_input.mp4` ก่อน ด้วยขั้นตอนที่ 1-3 ด้านบน

### ❌ Worker แสดง `ImportError: SkyReelsV2ImageToVideoPipeline`
```bash
pip install "diffusers>=0.40.0"
```

### ❌ ดูล็อก worker
```bash
docker compose logs -f worker-video
docker compose logs -f worker-audio
docker compose logs -f worker-llm
```

### ❌ รีสตาร์ททุกอย่าง
```bash
docker compose down
docker compose up -d
```

### ❌ ลบข้อมูลและเริ่มใหม่ทั้งหมด
```bash
docker compose down -v   # ⚠️ ลบ database ด้วย
docker compose up -d
```

---

## โครงสร้างโปรเจกต์ (สรุปย่อ)

```
world-engine/
├── backend/
│   ├── api/routes/     ← API endpoints (video, audio, tts, llm, stream, ...)
│   ├── workers/        ← งานพื้นหลัง (AI generation, chat, idle, composite)
│   ├── core/           ← config + celery
│   ├── models/         ← database models
│   └── requirements.txt
├── docker-compose.yml  ← เปิดทั้งระบบด้วยคำสั่งเดียว
├── scripts/
│   ├── setup.sh        ← ติดตั้งครั้งแรก
│   └── install_models.sh ← ดาวน์โหลด AI models
└── streaming/
    └── nginx-rtmp.conf ← RTMP server config
```

---

## API สรุปฉบับย่อ

| Method | URL | ทำอะไร |
|---|---|---|
| POST | `/api/v1/video/generate` | สร้างวิดีโอ (SkyReels V2) |
| GET | `/api/v1/video/{id}` | ดูสถานะงาน |
| POST | `/api/v1/audio/generate` | สร้างเสียง (AudioLDM2) |
| POST | `/api/v1/tts/generate` | พากย์เสียง (Tortoise TTS) |
| POST | `/api/v1/llm/generate` | สร้างเรื่องราว (Mistral 7B) |
| POST | `/api/v1/composite/build` | รวมวิดีโอ + เสียง → stream_input.mp4 |
| POST | `/api/v1/stream/start` | เริ่มสตรีมไป YouTube |
| POST | `/api/v1/stream/stop` | หยุดสตรีม |
| GET | `/api/v1/stream/status` | ตรวจสอบสถานะ |
| POST | `/api/v1/donations` | บันทึกบริจาค (manual หรือจาก chat) |
| GET | `/health` | ตรวจสอบว่า API ทำงาน |

---

*World Engine – MIT License*
