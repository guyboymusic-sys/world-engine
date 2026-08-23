"""API integration tests."""
import pytest
from httpx import AsyncClient, ASGITransport
from unittest.mock import MagicMock, patch
from backend.main import app
from backend.core.config import get_settings
from backend.workers import video_worker


@pytest.mark.asyncio
async def test_health():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


@pytest.mark.asyncio
async def test_stream_status():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.get("/api/v1/stream/status")
    assert resp.status_code == 200
    data = resp.json()
    assert "streaming" in data


def test_default_video_model_setting():
    get_settings.cache_clear()
    settings = get_settings()
    assert settings.video_model_id == "damo-vilab/text-to-video-ms-1.7b"


def test_video_worker_loads_configured_pipeline():
    mock_pipe = MagicMock()
    mock_pipe.to.return_value = mock_pipe
    mock_diffusion_pipeline = MagicMock()
    mock_diffusion_pipeline.from_pretrained.return_value = mock_pipe

    video_worker._pipeline = None

    with patch.dict("sys.modules", {"diffusers": MagicMock(DiffusionPipeline=mock_diffusion_pipeline)}):
        video_worker._get_pipeline()

    mock_diffusion_pipeline.from_pretrained.assert_called_once_with(
        video_worker.settings.video_model_id,
        torch_dtype="float16",
        cache_dir=video_worker.settings.models_dir,
    )
