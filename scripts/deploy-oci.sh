#!/usr/bin/env bash
# Sync server tree to OCI and rebuild containers.
set -euo pipefail

HOST="${CARDGAME_OCI_HOST:-ubuntu@84.8.220.240}"
REMOTE_DIR="${CARDGAME_OCI_DIR:-~/cardgame}"
SSH_KEY="${CARDGAME_OCI_KEY:-$HOME/.ssh/id_upsell}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

SA_SRC="${CARDGAME_FIREBASE_SA:-}"
if [[ -z "$SA_SRC" ]]; then
  if [[ -f "$ROOT/secrets/firebase-adminsdk.json" ]]; then
    SA_SRC="$ROOT/secrets/firebase-adminsdk.json"
  elif [[ -f "$ROOT/shadow-hand-firebase-adminsdk-fbsvc-5ba02708db.json" ]]; then
    SA_SRC="$ROOT/shadow-hand-firebase-adminsdk-fbsvc-5ba02708db.json"
  fi
fi

# Ensure local secrets path exists for compose volume default.
mkdir -p "${ROOT}/secrets"
if [[ -n "${SA_SRC}" && -f "${SA_SRC}" ]]; then
  if [[ "${SA_SRC}" != "${ROOT}/secrets/firebase-adminsdk.json" ]]; then
    cp "${SA_SRC}" "${ROOT}/secrets/firebase-adminsdk.json"
    chmod 600 "${ROOT}/secrets/firebase-adminsdk.json"
  fi
fi

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
  --exclude secrets \
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

# FCM service-account JSON (never via git).
if [[ -f "${ROOT}/secrets/firebase-adminsdk.json" ]]; then
  ssh -i "${SSH_KEY}" "${HOST}" "mkdir -p ${REMOTE_DIR}/secrets && chmod 700 ${REMOTE_DIR}/secrets"
  rsync -avz -e "ssh -i ${SSH_KEY}" \
    "${ROOT}/secrets/firebase-adminsdk.json" \
    "${HOST}:${REMOTE_DIR}/secrets/firebase-adminsdk.json"
  ssh -i "${SSH_KEY}" "${HOST}" "chmod 600 ${REMOTE_DIR}/secrets/firebase-adminsdk.json"
else
  echo "warn: no Firebase SA JSON found — FCM will stay disabled on server" >&2
fi

ADMIN_SECRET_LOCAL="$(
  grep -E '^ADMIN_PUSH_SECRET=' "${ROOT}/.env" 2>/dev/null | head -1 | cut -d= -f2- || true
)"

# Upsert FCM-related keys on remote .env (compose does not sync .env).
ssh -i "${SSH_KEY}" "${HOST}" \
  REMOTE_DIR="${REMOTE_DIR}" \
  ADMIN_SECRET_LOCAL="${ADMIN_SECRET_LOCAL}" \
  'bash -s' <<'REMOTE'
set -euo pipefail
cd "$REMOTE_DIR"
touch .env
upsert() {
  local key="$1"
  local val="$2"
  if grep -q "^${key}=" .env; then
    grep -v "^${key}=" .env > .env.tmp
    mv .env.tmp .env
  fi
  printf '%s=%s\n' "$key" "$val" >> .env
}
upsert FIREBASE_SERVICE_ACCOUNT_JSON /run/secrets/firebase-adminsdk.json
upsert FIREBASE_SA_HOST_PATH ./secrets/firebase-adminsdk.json
if [[ -n "${ADMIN_SECRET_LOCAL:-}" ]]; then
  upsert ADMIN_PUSH_SECRET "$ADMIN_SECRET_LOCAL"
fi
REMOTE

ssh -i "${SSH_KEY}" "${HOST}" \
  "cd ${REMOTE_DIR} && sudo docker compose up --build -d && sudo docker compose ps && curl -sS http://127.0.0.1:8080/health && echo && sudo docker compose logs --tail=40 server"
