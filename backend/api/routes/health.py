"""Health check endpoint."""
from fastapi import APIRouter
from backend.core.config import get_settings

router = APIRouter()
settings = get_settings()


@router.get("")
async def health():
    return {"status": "ok", "service": "world-engine"}
