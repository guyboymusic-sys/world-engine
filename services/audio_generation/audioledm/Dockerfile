# Dockerfile for AudioLDM2
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
    diffusers \
    transformers \
    librosa \
    soundfile \
    scipy \
    accelerate \
    safetensors

# Clone AudioLDM2
RUN git clone https://github.com/haoheliu/AudioLDM2.git /app/audioledm2

WORKDIR /app/audioledm2

# Install AudioLDM2 dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy API wrapper
COPY services/audio_generation/audioledm/api_audioledm.py /app/api_audioledm.py

EXPOSE 8003

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8003/health || exit 1

CMD ["python", "/app/api_audioledm.py"]
