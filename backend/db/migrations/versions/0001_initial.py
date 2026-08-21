"""Initial migration – create all tables.

Revision ID: 0001
Revises:
Create Date: 2026-08-21
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "generation_jobs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("job_type", sa.String(32), nullable=False),
        sa.Column(
            "status",
            sa.Enum("pending", "started", "success", "failure", name="jobstatus"),
            nullable=False,
            server_default="pending",
        ),
        sa.Column("prompt", sa.Text, nullable=False),
        sa.Column("result_path", sa.Text, nullable=True),
        sa.Column("error_message", sa.Text, nullable=True),
        sa.Column("celery_task_id", sa.String(128), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        "donations",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("donor_name", sa.String(128), nullable=False),
        sa.Column("amount_usd", sa.Float, nullable=False),
        sa.Column("message", sa.Text, nullable=True),
        sa.Column("youtube_event_id", sa.String(256), nullable=True, unique=True),
        sa.Column("job_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("generation_jobs.id"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        "stream_sessions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("started_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("viewer_count_peak", sa.Integer, default=0),
        sa.Column("total_donations", sa.Float, default=0.0),
        sa.Column("is_active", sa.Boolean, default=False),
    )


def downgrade() -> None:
    op.drop_table("donations")
    op.drop_table("generation_jobs")
    op.drop_table("stream_sessions")
    op.execute("DROP TYPE IF EXISTS jobstatus")
