"""Test configuration – mock out GPU and external service dependencies.

Workers import torch and diffusers at module level.  In a CI environment
these libraries are not installed (no GPU).  We stub them out here so the
FastAPI app can be imported and tested without a GPU.
"""
import sys
from unittest.mock import MagicMock
import unittest.mock as mock

# ── Stub heavyweight GPU libraries before any app code is imported ─────────

# torch
torch_mock = MagicMock()
torch_mock.cuda.is_available.return_value = False
torch_mock.float16 = "float16"
torch_mock.no_grad = MagicMock(return_value=MagicMock(__enter__=MagicMock(), __exit__=MagicMock()))
sys.modules.setdefault("torch", torch_mock)

# diffusers
sys.modules.setdefault("diffusers", MagicMock())

# soundfile
sys.modules.setdefault("soundfile", MagicMock())

# imageio
sys.modules.setdefault("imageio", MagicMock())

# tortoise
for mod in ("tortoise", "tortoise.api", "tortoise.utils", "tortoise.utils.audio"):
    sys.modules.setdefault(mod, MagicMock())

# torchaudio
sys.modules.setdefault("torchaudio", MagicMock())

# transformers
sys.modules.setdefault("transformers", MagicMock())

# structlog
structlog_mock = MagicMock()
structlog_mock.get_logger.return_value = MagicMock()
sys.modules.setdefault("structlog", structlog_mock)

# ── Database – patch async engine so no real PG connection is needed ──────
_engine_patch = mock.patch(
    "sqlalchemy.ext.asyncio.create_async_engine",
    return_value=MagicMock(),
)
_engine_patch.start()

_session_patch = mock.patch(
    "sqlalchemy.ext.asyncio.async_sessionmaker",
    return_value=MagicMock(),
)
_session_patch.start()

# Patch sync create_engine used by Celery workers
_sync_engine_patch = mock.patch(
    "sqlalchemy.create_engine",
    return_value=MagicMock(),
)
_sync_engine_patch.start()
