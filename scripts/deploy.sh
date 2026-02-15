#!/usr/bin/env bash
set -euo pipefail

# Required env vars (passed from Jenkins):
# DEPLOY_ENV, REMOTE_HOST, REMOTE_USER, REMOTE_DIR, BACKEND_SERVICE

if [[ -z "${DEPLOY_ENV:-}" || -z "${REMOTE_HOST:-}" || -z "${REMOTE_USER:-}" || -z "${REMOTE_DIR:-}" || -z "${BACKEND_SERVICE:-}" ]]; then
  echo "Missing required env vars. Need DEPLOY_ENV, REMOTE_HOST, REMOTE_USER, REMOTE_DIR, BACKEND_SERVICE"
  exit 1
fi

DEPLOY_MODE="${DEPLOY_MODE:-scp}"
echo "Deploying ${DEPLOY_ENV} in mode=${DEPLOY_MODE} to ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}"

FRONTEND_DIR="${REMOTE_DIR}/frontend"
BACKEND_DIR="${REMOTE_DIR}/backend"

if [[ "${DEPLOY_MODE}" == "docker" ]]; then
  # Docker mode: backend folder should contain Dockerfile/docker-compose.yml on server.
  rsync -az --delete \
    --exclude node_modules \
    --exclude .env \
    backend/ "${REMOTE_USER}@${REMOTE_HOST}:${BACKEND_DIR}/"

  ssh "${REMOTE_USER}@${REMOTE_HOST}" bash <<EOF
set -euo pipefail
cd "${BACKEND_DIR}"
docker compose pull || true
docker compose up -d --build
docker compose ps
EOF
  echo "Docker deployment complete."
  exit 0
fi

# Default mode: SCP/rsync static + backend deploy
ssh "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p '${FRONTEND_DIR}' '${BACKEND_DIR}'"
rsync -az --delete build/web/ "${REMOTE_USER}@${REMOTE_HOST}:${FRONTEND_DIR}/"
rsync -az --delete \
  --exclude node_modules \
  --exclude .env \
  --exclude data/*.json \
  backend/ "${REMOTE_USER}@${REMOTE_HOST}:${BACKEND_DIR}/"
ssh "${REMOTE_USER}@${REMOTE_HOST}" bash <<EOF
set -euo pipefail
cd "${BACKEND_DIR}"
npm ci --omit=dev
npx prisma generate
npx prisma migrate deploy

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl restart "${BACKEND_SERVICE}"
  sudo systemctl status "${BACKEND_SERVICE}" --no-pager || true
else
  echo "systemctl not found. Restart backend manually."
fi
EOF

echo "Deployment complete."
