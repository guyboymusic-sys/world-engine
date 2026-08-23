"""Application settings loaded from environment variables."""
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Database
    database_url: str = "postgresql+asyncpg://worldengine:worldengine@localhost:5432/worldengine"
    database_sync_url: str = "postgresql+psycopg2://worldengine:worldengine@localhost:5432/worldengine"

    # Redis / Celery
    redis_url: str = "redis://localhost:6379/0"

    # Auth
    secret_key: str = "change-me"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    # AI models
    models_dir: str = "/models"
    video_model_id: str = "damo-vilab/text-to-video-ms-1.7b"
    audioldm2_model_id: str = "cvssp/audioldm2-large"
    mistral_model_id: str = "mistralai/Mistral-7B-Instruct-v0.3"
    # Tortoise TTS stores its weights in a sub-directory to avoid clashes
    tortoise_models_dir: str = "/models/tortoise"
    tortoise_voice: str = "random"

    # Streaming
    rtmp_server: str = "rtmp://localhost:1935"
    stream_key: str = "live"
    youtube_stream_key: str = ""

    # YouTube
    youtube_api_key: str = ""
    youtube_channel_id: str = ""
    youtube_live_chat_id: str = ""

    # Video generation
    video_fps: int = 24
    video_width: int = 1280
    video_height: int = 720
    video_duration_seconds: int = 5

    # Audio generation
    audio_duration_seconds: int = 10
    audio_sample_rate: int = 16000

    # Worker concurrency (used by docker-compose and Celery CLI)
    video_worker_concurrency: int = 1
    audio_worker_concurrency: int = 2
    tts_worker_concurrency: int = 2
    llm_worker_concurrency: int = 1

    # Internal API base URL (used by workers to call the API service)
    # In Docker: "http://api:8000/api/v1" | Local dev: "http://localhost:8000/api/v1"
    api_base_url: str = "http://api:8000/api/v1"

    # Idle level system
    # How long (seconds) without a donation before idle content fires
    idle_trigger_seconds: int = 120
    # Starting level for idle system (1-10, increases over time)
    idle_level: int = 1


@lru_cache
def get_settings() -> Settings:
    return Settings()
