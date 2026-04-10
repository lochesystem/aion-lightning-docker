#!/usr/bin/env bash
# Bootstrap mínimo para VPS Ubuntu: Docker Engine + Compose plugin + utilitários.
# Uso: sudo ./scripts/bootstrap-vps.sh
# Depois: clonar este repo + aion-lightning-work, criar compose.env, docker compose up.

set -euo pipefail

if [[ "${EUID:-0}" -ne 0 ]]; then
  echo "Corre com sudo: sudo $0" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y ca-certificates curl git

# Docker oficial (Ubuntu)
if ! command -v docker &>/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  # shellcheck source=/dev/null
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

systemctl enable --now docker

echo ""
echo "OK: $(docker --version)"
echo "     $(docker compose version)"
echo "Seguinte: adiciona o utilizador ao grupo docker (opcional):"
echo "  sudo usermod -aG docker \"\$USER\" && newgrp docker"
echo "Depois: git clone ... / clona aion-lightning-work, compose.env, docker compose up."
