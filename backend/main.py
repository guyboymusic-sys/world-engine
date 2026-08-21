"""FastAPI application entry point."""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import structlog

from backend.api.routes import video, audio, tts, llm, donations, stream, health
from backend.core.config import get_settings

settings = get_settings()
logger = structlog.get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("World Engine API starting up")
    yield
    logger.info("World Engine API shutting down")


app = FastAPI(
    title="World Engine API",
    description="AI-powered interactive streaming game backend",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router, prefix="/health", tags=["health"])
app.include_router(video.router, prefix="/api/v1/video", tags=["video"])
app.include_router(audio.router, prefix="/api/v1/audio", tags=["audio"])
app.include_router(tts.router, prefix="/api/v1/tts", tags=["tts"])
app.include_router(llm.router, prefix="/api/v1/llm", tags=["llm"])
app.include_router(donations.router, prefix="/api/v1/donations", tags=["donations"])
app.include_router(stream.router, prefix="/api/v1/stream", tags=["stream"])

app.mount("/outputs", StaticFiles(directory="/outputs"), name="outputs")
