"""Helpers for migration database URLs."""


def resolve_alembic_url(database_url: str, database_sync_url: str | None) -> str:
    if database_sync_url:
        return database_sync_url

    if "://" not in database_url:
        return database_url

    scheme, remainder = database_url.split("://", 1)
    return f"{scheme.split('+', 1)[0]}://{remainder}"
