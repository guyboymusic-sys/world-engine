# World Engine Quick Start (RunPod RTX / Docker)

This guide is intentionally detailed for first-time deployment on RunPod (PyTorch template, Python 3.11).

---

## 1) Environment Preparation

### Why `nano` is missing on RunPod
Many RunPod images use minimal shell/tooling. You may have `bash` but not editors like `nano`/`vim` preinstalled.
Use shell-native editing methods below.

### Prerequisites
Run these from `/workspace`:

```sh
python3 --version
pip --version
docker --version
docker compose version
nvidia-smi
```

Expected:
- Python 3.11.x (recommended)
- Docker + Compose available
- GPU shown in `nvidia-smi`

### Docker GPU check

```sh
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

If this fails, fix NVIDIA runtime before continuing.

---

## 2) Step-by-Step Installation

### A. Clone repository

```sh
cd /workspace
git clone https://github.com/guyboymusic-sys/world-engine.git
cd world-engine
```

### B. Create `.env`

```sh
cp backend/.env.example backend/.env
```

### C. Edit files without nano/vim

#### Option 1: replace one value with `sed`

```sh
sed -i 's/^SECRET_KEY=.*/SECRET_KEY=replace-with-long-random-secret/' backend/.env
sed -i 's/^YOUTUBE_STREAM_KEY=.*/YOUTUBE_STREAM_KEY=replace-with-youtube-stream-key/' backend/.env
```

#### Option 2: append/update values with `echo` + `tee`

```sh
echo 'SECRET_KEY=replace-with-long-random-secret' | tee -a backend/.env
echo 'YOUTUBE_STREAM_KEY=replace-with-youtube-stream-key' | tee -a backend/.env
```

#### Option 3: write a full file block with `cat <<EOF`

```sh
cat > backend/.env <<'ENVEOF'
DATABASE_URL=******db:5432/worldengine
DATABASE_SYNC_URL=******db:5432/worldengine
REDIS_URL=redis://redis:6379/0
SECRET_KEY=replace-with-long-random-secret
MODELS_DIR=/models
VIDEO_MODEL_ID=damo-vilab/text-to-video-ms-1.7b
AUDIOLDM2_MODEL_ID=cvssp/audioldm2-large
MISTRAL_MODEL_ID=mistralai/Mistral-7B-Instruct-v0.3
YOUTUBE_STREAM_KEY=replace-with-youtube-stream-key
ENVEOF
```

### D. Verify `.env` critical values

```sh
grep -E '^(SECRET_KEY|YOUTUBE_STREAM_KEY|MODELS_DIR|VIDEO_MODEL_ID)=' backend/.env
```

### E. Run setup

```sh
sh scripts/setup.sh
```

What setup does:
1. Installs pinned Python dependencies (`backend/requirements-pinned.txt`)
2. Downloads models into `/models`
3. Starts `db`, `redis`, `nginx-rtmp`
4. Runs Alembic migrations

---

## 3) Model Download & Installation Details

### Models used
- **Video**: `damo-vilab/text-to-video-ms-1.7b` (ModelScope text-to-video)
- **Audio**: `cvssp/audioldm2-large`
- **TTS**: `jbetker/tortoise-tts-v2` (pre-cached by setup)
- **LLM**: `mistralai/Mistral-7B-Instruct-v0.3`

### Progress tracking

```sh
# Terminal 1: run installer
sh scripts/install_models.sh /models

# Terminal 2: monitor growth
watch -n 5 'du -sh /models'
```

### Disk estimates
- Video model: ~10–12 GB
- AudioLDM2: ~5 GB
- Tortoise: ~8 GB
- Mistral: ~14 GB
- **Recommended free space: 80+ GB**

### Resume interrupted downloads
`snapshot_download()` resumes automatically if files already exist in cache.
Re-run safely:

```sh
sh scripts/install_models.sh /models
```

### Verify model files

```sh
find /models -maxdepth 3 -type f | head
```

Optional checksum example:

```sh
sha256sum /models/models--damo-vilab--text-to-video-ms-1.7b/* 2>/dev/null | head
```

---

## 4) Docker Startup & Verification

### Start infra first

```sh
docker compose up -d db redis nginx-rtmp
docker compose ps
```

### Check health

```sh
docker compose exec -T db pg_isready -U worldengine
docker compose logs --tail=100 redis
docker compose logs --tail=100 nginx-rtmp
```

### Start API and workers

```sh
docker compose up -d api worker-video worker-audio worker-tts worker-llm worker-composite worker-chat-idle beat flower
```

### Verify all services

```sh
docker compose ps
curl -fsS http://localhost:8000/health
curl -fsS http://localhost:8000/api/v1/stream/status
```

### Verify GPU in worker container

```sh
docker compose exec -T worker-video nvidia-smi
```

---

## 5) First Run Testing

### API reachable

```sh
curl -fsS http://localhost:8000/health
```

### Video generation test

```sh
curl -X POST http://localhost:8000/api/v1/video/generate \
  -H 'Content-Type: application/json' \
  -d '{"prompt":"a cinematic sunrise over futuristic city","duration_seconds":5}'
```

### Audio generation test

```sh
curl -X POST http://localhost:8000/api/v1/audio/generate \
  -H 'Content-Type: application/json' \
  -d '{"prompt":"calm ambient wind and distant thunder","duration_seconds":8}'
```

### TTS test

```sh
curl -X POST http://localhost:8000/api/v1/tts/generate \
  -H 'Content-Type: application/json' \
  -d '{"text":"Welcome to the world engine stream.","voice":"random"}'
```

### RTMP start/stop test

```sh
curl -X POST http://localhost:8000/api/v1/stream/start
curl http://localhost:8000/api/v1/stream/status
curl -X POST http://localhost:8000/api/v1/stream/stop
```

---

## 6) Troubleshooting Reference

### Dependency resolver failures (`ResolutionImpossible`)
- Use pinned file only:
  ```sh
  pip install -r backend/requirements-pinned.txt
  ```
- Do not mix random upgrades/downgrades unless you repin all ML libs together.

### `nano: command not found`
Use `sed`, `cat <<EOF`, or `echo | tee` methods above.

### GPU memory issues
- Lower video duration/fps
- Run fewer workers in parallel
- Check GPU usage:
  ```sh
  nvidia-smi
  ```

### Docker volume/storage issues

```sh
docker system df
df -h
```

If full, prune unused resources carefully:

```sh
docker system prune -f
```

### Model load failures

```sh
docker compose logs --tail=200 worker-video
docker compose logs --tail=200 worker-audio
docker compose logs --tail=200 worker-llm
```

Re-run model installation:

```sh
sh scripts/install_models.sh /models
```

### RTMP issues
- Verify stream key in `backend/.env`
- Verify nginx-rtmp is up
- Check logs:
  ```sh
  docker compose logs --tail=200 nginx-rtmp
  ```

### Full reset (destructive)

```sh
docker compose down -v
rm -rf .venv
python3 -m venv .venv
. .venv/bin/activate
pip install -r backend/requirements-pinned.txt
sh scripts/setup.sh
```

---

For full variable descriptions, required/optional matrix, and security/performance guidance, see `CONFIGURATION_REFERENCE.md`.
