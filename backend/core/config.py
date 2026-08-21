"""Application settings loaded from environment variables."""
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Database
    database_url: str = "******localhost:5432/worldengine"
    database_sync_url: str = "******localhost:5432/worldengine"

    # Redis / Celery
    redis_url: str = "redis://localhost:6379/0"

    # Auth
    secret_key: str = "change-me"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    # AI models
    models_dir: str = "/models"
    skyreels_model_id: str = "Skywork/SkyReels-V2-I2V-14B-720P"
    audioldm2_model_id: str = "cvssp/audioldm2-large"
    mistral_model_id: str = "mistralai/Mistral-7B-Instruct-v0.3"
    tortoise_voice: str = "random"

    # Streaming
    rtmp_server: str = "rtmp://localhost:1935"
    stream_key: str = "live"
    youtube_stream_key: str = ""

    # YouTube
    youtube_api_key: str = ""
    youtube_channel_id: str = ""

    # Video generation
    video_fps: int = 24
    video_width: int = 1280
    video_height: int = 720
    video_duration_seconds: int = 5

    # Audio generation
    audio_duration_seconds: int = 10
    audio_sample_rate: int = 16000


@lru_cache
def get_settings() -> Settings:
    return Settings()
