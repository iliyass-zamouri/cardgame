#!/usr/bin/env bash
# Sync server tree to OCI and rebuild containers.
set -euo pipefail

HOST="${CARDGAME_OCI_HOST:-ubuntu@84.8.220.240}"
REMOTE_DIR="${CARDGAME_OCI_DIR:-~/cardgame}"
SSH_KEY="${CARDGAME_OCI_KEY:-$HOME/.ssh/id_upsell}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

rsync -avz -e "ssh -i ${SSH_KEY}" \
  --exclude node_modules \
  --exclude .git \
  --exclude build \
  --exclude .dart_tool \
  --exclude ios \
  --exclude android \
  --exclude macos \
  --exclude linux \
  --exclude windows \
  --exclude web \
  --exclude .env \
  --exclude .fvm \
  --exclude .idea \
  "${ROOT}/Dockerfile" \
  "${ROOT}/docker-compose.yml" \
  "${ROOT}/package.json" \
  "${ROOT}/package-lock.json" \
  "${ROOT}/.dockerignore" \
  "${HOST}:${REMOTE_DIR}/"

rsync -avz -e "ssh -i ${SSH_KEY}" \
  --exclude node_modules \
  --delete \
  "${ROOT}/server/" "${HOST}:${REMOTE_DIR}/server/"

ssh -i "${SSH_KEY}" "${HOST}" "cd ${REMOTE_DIR} && sudo docker compose up --build -d && sudo docker compose ps && curl -sS http://127.0.0.1:8080/health"
