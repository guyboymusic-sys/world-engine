"""Compositing worker – merges generated video + audio into stream_input.mp4.

This is the glue between AI generation and the RTMP stream.  After video and
audio workers finish, this task combines their outputs with FFmpeg and writes
/outputs/stream_input.mp4 – the file that the streaming endpoint loops.
"""
import uuid
import subprocess
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from backend.core.config import get_settings
from backend.models.models import GenerationJob, JobStatus
from backend.core.celery_app import celery_app

settings = get_settings()

_engine = None
_Session = None


def _get_session_factory():
    global _engine, _Session
    if _Session is None:
        _engine = create_engine(settings.database_sync_url)
        _Session = sessionmaker(bind=_engine)
    return _Session

OUTPUT_DIR = Path("/outputs")

# Path that the streaming endpoint reads from
STREAM_INPUT = OUTPUT_DIR / "stream_input.mp4"
STREAM_INPUT_TMP = OUTPUT_DIR / "stream_input.tmp.mp4"


@celery_app.task(
    name="backend.workers.composite_worker.composite_task",
    bind=True,
    queue="composite",
)
def composite_task(
    self,
    job_id: str,
    video_path: str,
    audio_path: str,
):
    """Merge *video_path* and *audio_path* into /outputs/stream_input.mp4.

    Uses FFmpeg to overlay audio on video.  The output file is written to a
    temporary path first, then atomically renamed so the streaming FFmpeg
    process always sees a valid file.
    """
    with _get_session_factory()() as db:
        job = db.get(GenerationJob, uuid.UUID(job_id))
        job.status = JobStatus.started
        job.celery_task_id = self.request.id
        db.commit()

    try:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        # Build the FFmpeg command:
        #   -i video  -i audio  → mix together, shortest wins
        cmd = [
            "ffmpeg",
            "-y",                          # overwrite temp file
            "-i", video_path,
            "-i", audio_path,
            "-c:v", "copy",                # video already encoded – just copy
            "-c:a", "aac",
            "-b:a", "128k",
            "-ar", "44100",
            "-shortest",                   # stop at the shorter of the two
            "-movflags", "+faststart",     # web-compatible MP4
            str(STREAM_INPUT_TMP),
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(f"FFmpeg error:\n{result.stderr}")

        # Atomic rename so the streaming process always sees a complete file
        STREAM_INPUT_TMP.replace(STREAM_INPUT)

        with _get_session_factory()() as db:
            job = db.get(GenerationJob, uuid.UUID(job_id))
            job.status = JobStatus.success
            job.result_path = str(STREAM_INPUT)
            db.commit()

        return str(STREAM_INPUT)

    except Exception as exc:
        with _get_session_factory()() as db:
            job = db.get(GenerationJob, uuid.UUID(job_id))
            job.status = JobStatus.failure
            job.error_message = str(exc)
            db.commit()
        raise
