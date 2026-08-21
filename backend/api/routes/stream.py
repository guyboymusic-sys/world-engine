"""Stream control endpoints – start/stop RTMP push."""
import uuid
import subprocess
import asyncio
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from backend.db.database import get_db
from backend.models.models import StreamSession
from backend.core.config import get_settings

router = APIRouter()
settings = get_settings()

_stream_process: subprocess.Popen | None = None


class StreamSessionOut:
    pass


@router.post("/start", status_code=200)
async def start_stream(db: AsyncSession = Depends(get_db)):
    global _stream_process

    # Mark any existing active sessions as ended
    result = await db.execute(select(StreamSession).where(StreamSession.is_active == True))  # noqa: E712
    for s in result.scalars().all():
        s.is_active = False

    session = StreamSession(is_active=True)
    db.add(session)
    await db.commit()

    rtmp_url = f"{settings.rtmp_server}/live/{settings.stream_key}"
    if settings.youtube_stream_key:
        rtmp_url = f"rtmp://a.rtmp.youtube.com/live2/{settings.youtube_stream_key}"

    # Start FFmpeg RTMP push from local RTMP source
    cmd = [
        "ffmpeg",
        "-re",
        "-stream_loop", "-1",
        "-i", "/outputs/stream_input.mp4",
        "-c:v", "libx264",
        "-preset", "veryfast",
        "-b:v", "3000k",
        "-maxrate", "3000k",
        "-bufsize", "6000k",
        "-pix_fmt", "yuv420p",
        "-g", str(settings.video_fps * 2),
        "-c:a", "aac",
        "-b:a", "128k",
        "-ar", "44100",
        "-f", "flv",
        rtmp_url,
    ]

    _stream_process = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return {"status": "streaming", "rtmp_url": rtmp_url, "session_id": str(session.id)}


@router.post("/stop", status_code=200)
async def stop_stream(db: AsyncSession = Depends(get_db)):
    global _stream_process
    if _stream_process:
        _stream_process.terminate()
        _stream_process = None

    result = await db.execute(select(StreamSession).where(StreamSession.is_active == True))  # noqa: E712
    for s in result.scalars().all():
        s.is_active = False
    await db.commit()

    return {"status": "stopped"}


@router.get("/status")
async def stream_status():
    global _stream_process
    running = _stream_process is not None and _stream_process.poll() is None
    return {"streaming": running}
