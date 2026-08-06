#!/usr/bin/env bash
# Deploy cardgame backend to Oracle VM (84.8.222.159:8080)
set -euo pipefail
HOST="${DEPLOY_HOST:-84.8.222.159}"
REMOTE_DIR="${REMOTE_DIR:-/opt/cardgame}"

echo "Building image..."
docker compose -f server/docker-compose.yml build cardgame

echo "Save/load via ssh optional — prefer git pull + compose on VM"
ssh "ubuntu@${HOST}" "mkdir -p ${REMOTE_DIR}"
rsync -az --delete server/ "ubuntu@${HOST}:${REMOTE_DIR}/server/"
rsync -az docker-compose.yml "ubuntu@${HOST}:${REMOTE_DIR}/docker-compose.yml"

ssh "ubuntu@${HOST}" "cd ${REMOTE_DIR} && docker compose up -d --build cardgame mysql"

echo "Health:"
ssh "ubuntu@${HOST}" "curl -fsS http://127.0.0.1:8080/healthz || true"
echo "Deploy done."
