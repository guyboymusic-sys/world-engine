"""Deployment script regression tests."""
from pathlib import Path
import os
import shutil
import subprocess
import textwrap


REPO_ROOT = Path(__file__).resolve().parents[2]


def _write_executable(path: Path, content: str) -> None:
    path.write_text(textwrap.dedent(content))
    path.chmod(0o755)


def _symlink_command(fakebin: Path, name: str) -> None:
    target = shutil.which(name)
    assert target is not None, f"missing system command for test harness: {name}"
    (fakebin / name).symlink_to(target)


def _create_fake_python(fakebin: Path) -> None:
    _write_executable(
        fakebin / "python3.11",
        """\
        #!/bin/bash
        set -euo pipefail
        if [ "$1" = "-m" ] && [ "$2" = "venv" ]; then
          target="$3"
          mkdir -p "$target/bin"
          cat > "$target/bin/activate" <<'EOF'
        export PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd):$PATH"
        EOF
          cat > "$target/bin/python" <<'EOF'
        #!/bin/bash
        exit 0
        EOF
          cat > "$target/bin/alembic" <<'EOF'
        #!/bin/bash
        exit 0
        EOF
          chmod +x "$target/bin/python" "$target/bin/alembic"
        fi
        """,
    )


def _create_fake_docker(fakebin: Path) -> None:
    _write_executable(
        fakebin / "docker",
        """\
        #!/bin/bash
        set -euo pipefail
        state_dir="${STATE_DIR:?}"
        case "$*" in
          "compose version")
            exit 0
            ;;
          "info")
            if [ -f "$state_dir/daemon-ready" ]; then
              exit 0
            fi
            exit 1
            ;;
          "compose up -d db redis")
            printf '%s\\n' 'compose-up' >> "$state_dir/docker.log"
            exit 0
            ;;
          "compose exec -T db pg_isready -U worldengine")
            exit 0
            ;;
          "compose exec -T redis redis-cli ping")
            exit 0
            ;;
        esac
        printf '%s\\n' "unexpected:$*" >> "$state_dir/docker.log"
        exit 1
        """,
    )


def _create_fake_docker_without_compose(fakebin: Path) -> None:
    _write_executable(
        fakebin / "docker",
        """\
        #!/bin/bash
        set -euo pipefail
        case "$*" in
          "compose version")
            exit 1
            ;;
          "info")
            exit 1
            ;;
        esac
        exit 1
        """,
    )


def _create_fake_installer_commands(fakebin: Path) -> None:
    _write_executable(
        fakebin / "id",
        """\
        #!/bin/bash
        if [ "${1:-}" = "-u" ]; then
          echo 0
        else
          /usr/bin/id "$@"
        fi
        """,
    )
    _write_executable(
        fakebin / "apt-get",
        """\
        #!/bin/bash
        set -euo pipefail
        state_dir="${STATE_DIR:?}"
        printf '%s\\n' "$*" >> "$state_dir/apt-get.log"
        if printf '%s' "$*" | grep -q 'docker-ce'; then
          cat > "${FAKEBIN:?}/docker" <<'EOF'
        #!/bin/bash
        set -euo pipefail
        state_dir="${STATE_DIR:?}"
        case "$*" in
          "compose version")
            exit 0
            ;;
          "info")
            if [ -f "$state_dir/daemon-ready" ]; then
              exit 0
            fi
            exit 1
            ;;
          "compose up -d db redis")
            printf '%s\\n' 'compose-up' >> "$state_dir/docker.log"
            exit 0
            ;;
          "compose exec -T db pg_isready -U worldengine")
            exit 0
            ;;
          "compose exec -T redis redis-cli ping")
            exit 0
            ;;
        esac
        printf '%s\\n' "unexpected:$*" >> "$state_dir/docker.log"
        exit 1
        EOF
          chmod +x "${FAKEBIN:?}/docker"
        fi
        """,
    )
    _write_executable(
        fakebin / "curl",
        """\
        #!/bin/bash
        set -euo pipefail
        output=''
        while [ "$#" -gt 0 ]; do
          if [ "$1" = "-o" ]; then
            output="$2"
            shift 2
          else
            shift
          fi
        done
        printf 'fake docker gpg key\\n' > "$output"
        """,
    )
    _write_executable(
        fakebin / "dpkg",
        """\
        #!/bin/bash
        if [ "${1:-}" = "--print-architecture" ]; then
          echo amd64
        else
          exit 1
        fi
        """,
    )
    _write_executable(
        fakebin / "systemctl",
        """\
        #!/bin/bash
        set -euo pipefail
        touch "${STATE_DIR:?}/daemon-ready"
        """,
    )
    _write_executable(
        fakebin / "service",
        """\
        #!/bin/bash
        set -euo pipefail
        touch "${STATE_DIR:?}/daemon-ready"
        """,
    )
    _write_executable(
        fakebin / "pgrep",
        """\
        #!/bin/bash
        [ -f "${STATE_DIR:?}/daemon-ready" ]
        """,
    )
    _write_executable(
        fakebin / "sudo",
        """\
        #!/bin/bash
        exec "$@"
        """,
    )


def _prepare_fakebin(fakebin: Path) -> None:
    fakebin.mkdir()
    for command in ("bash", "dirname", "cp", "seq", "sleep", "mkdir", "chmod", "cat", "sh", "grep", "install", "touch", "mv"):
        _symlink_command(fakebin, command)
    _create_fake_python(fakebin)
    _create_fake_installer_commands(fakebin)


def _script_env(tmp_path: Path, fakebin: Path) -> dict[str, str]:
    env = os.environ.copy()
    env["PATH"] = str(fakebin)
    env["FAKEBIN"] = str(fakebin)
    env["STATE_DIR"] = str(tmp_path)
    env["OS_RELEASE_FILE"] = str(tmp_path / "os-release")
    env["APT_KEYRINGS_DIR"] = str(tmp_path / "apt" / "keyrings")
    env["APT_SOURCES_DIR"] = str(tmp_path / "apt" / "sources.list.d")
    env["DOCKER_LOG_DIR"] = str(tmp_path / "var" / "log")
    return env


def test_deploy_bootstraps_docker_before_compose(tmp_path):
    fakebin = tmp_path / "fakebin"
    _prepare_fakebin(fakebin)
    (tmp_path / "scripts").mkdir()
    (tmp_path / "backend").mkdir()
    shutil.copy(REPO_ROOT / "deploy.sh", tmp_path / "deploy.sh")
    shutil.copy(REPO_ROOT / "scripts" / "install_docker.sh", tmp_path / "scripts" / "install_docker.sh")
    _write_executable(
        tmp_path / "scripts" / "run_all.sh",
        """\
        #!/bin/bash
        printf 'run-all\\n' >> "${STATE_DIR:?}/run_all.log"
        """,
    )
    (tmp_path / "backend" / "requirements.txt").write_text("")
    (tmp_path / "backend" / ".env.example").write_text("")
    (tmp_path / "os-release").write_text("ID=ubuntu\nVERSION_CODENAME=jammy\n")

    result = subprocess.run(
        ["bash", "deploy.sh"],
        cwd=tmp_path,
        env=_script_env(tmp_path, fakebin),
        check=True,
        capture_output=True,
        text=True,
    )

    assert "Installing Docker..." in result.stdout
    assert "Docker is ready" in result.stdout
    assert "docker-ce" in (tmp_path / "apt-get.log").read_text()
    assert (tmp_path / "run_all.log").read_text().strip() == "run-all"
    assert "compose-up" in (tmp_path / "docker.log").read_text()


def test_install_docker_only_starts_daemon_when_docker_is_already_installed(tmp_path):
    fakebin = tmp_path / "fakebin"
    _prepare_fakebin(fakebin)
    _create_fake_docker(fakebin)
    (tmp_path / "scripts").mkdir()
    shutil.copy(REPO_ROOT / "scripts" / "install_docker.sh", tmp_path / "scripts" / "install_docker.sh")

    subprocess.run(
        ["bash", "scripts/install_docker.sh"],
        cwd=tmp_path,
        env=_script_env(tmp_path, fakebin),
        check=True,
        capture_output=True,
        text=True,
    )

    assert not (tmp_path / "apt-get.log").exists()
    assert (tmp_path / "daemon-ready").exists()


def test_install_docker_reports_unsupported_platform_when_apt_is_missing(tmp_path):
    fakebin = tmp_path / "fakebin"
    _prepare_fakebin(fakebin)
    (fakebin / "apt-get").unlink()
    (tmp_path / "scripts").mkdir()
    shutil.copy(REPO_ROOT / "scripts" / "install_docker.sh", tmp_path / "scripts" / "install_docker.sh")

    result = subprocess.run(
        ["bash", "scripts/install_docker.sh"],
        cwd=tmp_path,
        env=_script_env(tmp_path, fakebin),
        capture_output=True,
        text=True,
    )

    assert result.returncode == 1
    assert "Automatic Docker installation currently supports apt-based systems only" in result.stdout


def test_install_docker_rewrites_only_the_docker_repo_entry(tmp_path):
    fakebin = tmp_path / "fakebin"
    _prepare_fakebin(fakebin)
    (tmp_path / "scripts").mkdir()
    shutil.copy(REPO_ROOT / "scripts" / "install_docker.sh", tmp_path / "scripts" / "install_docker.sh")
    (tmp_path / "os-release").write_text("ID=ubuntu\nVERSION_CODENAME=jammy\n")
    docker_list = tmp_path / "apt" / "sources.list.d" / "docker.list"
    docker_list.parent.mkdir(parents=True)
    docker_list.write_text(
        "# keep this comment\n"
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable\n"
        "deb http://mirror.example stable main\n"
    )

    subprocess.run(
        ["bash", "scripts/install_docker.sh"],
        cwd=tmp_path,
        env=_script_env(tmp_path, fakebin),
        check=True,
        capture_output=True,
        text=True,
    )

    docker_sources = docker_list.read_text().splitlines()
    assert "# keep this comment" in docker_sources
    assert "deb http://mirror.example stable main" in docker_sources
    assert "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" not in docker_sources
    assert (
        "deb [arch=amd64 signed-by="
        f"{tmp_path / 'apt' / 'keyrings' / 'docker.asc'}"
        "] https://download.docker.com/linux/ubuntu jammy stable"
    ) in docker_sources
    assert sum("https://download.docker.com/linux/" in line for line in docker_sources) == 1


def test_deploy_fails_fast_when_compose_is_missing_even_if_docker_exists(tmp_path):
    fakebin = tmp_path / "fakebin"
    _prepare_fakebin(fakebin)
    _create_fake_docker_without_compose(fakebin)
    (tmp_path / "scripts").mkdir()
    (tmp_path / "backend").mkdir()
    shutil.copy(REPO_ROOT / "deploy.sh", tmp_path / "deploy.sh")
    _write_executable(
        tmp_path / "scripts" / "install_docker.sh",
        """\
        #!/bin/bash
        printf 'installer-called\\n' >> "${STATE_DIR:?}/install.log"
        exit 0
        """,
    )
    _write_executable(
        tmp_path / "scripts" / "run_all.sh",
        """\
        #!/bin/bash
        exit 0
        """,
    )
    (tmp_path / "backend" / "requirements.txt").write_text("")
    (tmp_path / "backend" / ".env.example").write_text("")

    result = subprocess.run(
        ["bash", "deploy.sh"],
        cwd=tmp_path,
        env=_script_env(tmp_path, fakebin),
        capture_output=True,
        text=True,
    )

    assert result.returncode == 1
    assert "Docker Compose is not available" in result.stdout
    assert not (tmp_path / "install.log").exists()
