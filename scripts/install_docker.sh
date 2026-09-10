#!/usr/bin/env bash
set -euo pipefail

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "Docker installation requires root or sudo"
    exit 1
  fi
}

install_docker_packages() {
  export DEBIAN_FRONTEND=noninteractive

  . /etc/os-release

  run_as_root apt-get update
  run_as_root apt-get install -y ca-certificates curl gnupg
  run_as_root install -m 0755 -d /etc/apt/keyrings

  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    run_as_root curl -fsSL "https://download.docker.com/linux/${ID}/gpg" -o /etc/apt/keyrings/docker.asc
    run_as_root chmod a+r /etc/apt/keyrings/docker.asc
  fi

  arch="$(dpkg --print-architecture)"
  repo_url="https://download.docker.com/linux/${ID}"
  repo_suite="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
  if [ -z "${repo_suite}" ]; then
    echo "Unable to determine apt repository codename for Docker"
    exit 1
  fi
  run_as_root sh -c "echo 'deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] ${repo_url} ${repo_suite} stable' > /etc/apt/sources.list.d/docker.list"

  run_as_root apt-get update
  run_as_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

start_docker() {
  if docker info >/dev/null 2>&1; then
    return 0
  fi

  if command -v systemctl >/dev/null 2>&1; then
    run_as_root systemctl enable --now docker >/dev/null 2>&1 || true
  fi

  if ! docker info >/dev/null 2>&1 && command -v service >/dev/null 2>&1; then
    run_as_root service docker start >/dev/null 2>&1 || true
  fi

  if ! docker info >/dev/null 2>&1 && ! pgrep -x dockerd >/dev/null 2>&1; then
    run_as_root mkdir -p /var/log
    run_as_root sh -c 'nohup dockerd >/var/log/dockerd.log 2>&1 &'
  fi

  for _ in $(seq 1 30); do
    if docker info >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  echo "Docker daemon failed to start"
  exit 1
}

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer currently supports apt-based systems only"
  exit 1
fi

if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
  install_docker_packages
fi

start_docker

docker compose version >/dev/null 2>&1 || {
  echo "Docker Compose plugin is not available"
  exit 1
}

echo "Docker is ready"
