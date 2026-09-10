"""Settings tests for deployment defaults."""
import importlib
from backend.core.config import get_settings


def test_celery_urls_default_to_none(monkeypatch):
    monkeypatch.delenv("CELERY_BROKER_URL", raising=False)
    monkeypatch.delenv("CELERY_RESULT_BACKEND", raising=False)
    get_settings.cache_clear()

    settings = get_settings()

    assert settings.celery_broker_url is None
    assert settings.celery_result_backend is None


def test_celery_urls_can_be_set(monkeypatch):
    monkeypatch.setenv("CELERY_BROKER_URL", "redis://localhost:6379/1")
    monkeypatch.setenv("CELERY_RESULT_BACKEND", "redis://localhost:6379/2")
    get_settings.cache_clear()

    settings = get_settings()

    assert settings.celery_broker_url == "redis://localhost:6379/1"
    assert settings.celery_result_backend == "redis://localhost:6379/2"


def test_celery_app_falls_back_to_redis_url(monkeypatch):
    monkeypatch.setenv("REDIS_URL", "redis://localhost:6379/9")
    monkeypatch.delenv("CELERY_BROKER_URL", raising=False)
    monkeypatch.delenv("CELERY_RESULT_BACKEND", raising=False)
    get_settings.cache_clear()

    from backend.core import celery_app as celery_module
    importlib.reload(celery_module)

    assert celery_module.celery_app.conf.broker_url == "redis://localhost:6379/9"
    assert celery_module.celery_app.conf.result_backend == "redis://localhost:6379/9"


def test_celery_app_uses_mixed_override_and_fallback(monkeypatch):
    monkeypatch.setenv("REDIS_URL", "redis://localhost:6379/9")
    monkeypatch.setenv("CELERY_BROKER_URL", "redis://localhost:6379/7")
    monkeypatch.delenv("CELERY_RESULT_BACKEND", raising=False)
    get_settings.cache_clear()

    from backend.core import celery_app as celery_module
    importlib.reload(celery_module)

    assert celery_module.celery_app.conf.broker_url == "redis://localhost:6379/7"
    assert celery_module.celery_app.conf.result_backend == "redis://localhost:6379/9"
