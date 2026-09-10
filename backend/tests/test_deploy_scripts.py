"""Deployment script regression tests."""
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def test_deploy_bootstraps_docker_before_compose():
    deploy_script = (REPO_ROOT / "deploy.sh").read_text()

    assert 'bash "$ROOT_DIR/scripts/install_docker.sh"' in deploy_script
    assert deploy_script.index('bash "$ROOT_DIR/scripts/install_docker.sh"') < deploy_script.index(
        "docker compose up -d db redis"
    )
    assert "docker compose version >/dev/null 2>&1 || {" in deploy_script


def test_install_docker_script_installs_compose_plugin_and_starts_daemon():
    install_script = (REPO_ROOT / "scripts" / "install_docker.sh").read_text()

    assert "docker-compose-plugin" in install_script
    assert "docker-ce" in install_script
    assert "docker info >/dev/null 2>&1" in install_script
