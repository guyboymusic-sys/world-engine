"""Migration URL normalization tests."""
from backend.db.migrations.url_utils import resolve_alembic_url


def test_resolve_alembic_url_prefers_sync_url():
    assert (
        resolve_alembic_url(
            "******db:5432/worldengine",
            "******db:5432/worldengine",
        )
        == "******db:5432/worldengine"
    )


def test_resolve_alembic_url_falls_back_from_async_driver():
    assert (
        resolve_alembic_url(
            "******db:5432/worldengine",
            None,
        )
        == "******db:5432/worldengine"
    )


def test_resolve_alembic_url_strips_other_driver_suffixes():
    assert (
        resolve_alembic_url(
            "******db:5432/worldengine",
            None,
        )
        == "******db:5432/worldengine"
    )
