# Dockerfile for Tortoise TTS
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    ffmpeg \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir \
    tortoise-tts \
    librosa \
    soundfile \
    scipy \
    transformers \
    diffusers

# Copy API wrapper
COPY services/audio_generation/tortoise/api_tortoise.py /app/api_tortoise.py

EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

CMD ["python", "/app/api_tortoise.py"]
