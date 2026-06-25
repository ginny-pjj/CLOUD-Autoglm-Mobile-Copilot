#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f server/.env.cloud ]]; then
  cp server/.env.cloud.example server/.env.cloud
  echo "Created server/.env.cloud — please edit BIGMODEL_API_KEY first."
  exit 1
fi

docker compose up -d --build
sleep 3
curl -s "http://127.0.0.1:8000/health" || true
echo
echo "Server started. Open http://<your-public-ip>:8000/health"
echo "Next: docker exec -it autoglm-mobile-copilot adb connect <phone-ip>:5555"
