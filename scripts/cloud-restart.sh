#!/usr/bin/env bash
set -euo pipefail

ROOT="/root/autoglm-mobile-work"
ENV_FILE="$ROOT/server/.env"

cd "$ROOT"

if [[ ! -f "$ENV_FILE" ]] || ! grep -q '^BIGMODEL_API_KEY=.\+' "$ENV_FILE" 2>/dev/null; then
  echo "Creating $ENV_FILE ..."
  cat >"$ENV_FILE" <<'EOF'
BIGMODEL_API_KEY=REPLACE_ME
AUTOGLM_BASE_URL=https://open.bigmodel.cn/api/paas/v4
AUTOGLM_MODEL=autoglm-phone
ADB_CONNECT_ADDRESS=100.x.x.x:5555
PHONE_AGENT_DEVICE_ID=100.x.x.x:5555
AUTOGLM_SAFETY_CHECK=false
AUTOGLM_SENSITIVE_FILTER=false
PHONE_AGENT_FAIL_ON_TAKEOVER=false
PHONE_AGENT_CONTINUE_ON_SCREENSHOT_TAKEOVER=true
PHONE_AGENT_SCREENSHOT_TIMEOUT=120
PHONE_AGENT_SCREENSHOT_EXEC_OUT=true
PHONE_AGENT_SCREENSHOT_MAX_LONG_EDGE=360
PHONE_AGENT_ADB_CMD_TIMEOUT=120
PHONE_AGENT_MAX_STEPS=20
PHONE_AGENT_UI_TREE=true
TASK_TIMEOUT_SECONDS=600
PREPARE_HOME_BEFORE_TASK=true
EOF
  echo "Edit BIGMODEL_API_KEY first: nano $ENV_FILE"
  exit 1
fi

# Ensure remote-tuning keys exist
grep -q '^PHONE_AGENT_SCREENSHOT_TIMEOUT=' "$ENV_FILE" || echo 'PHONE_AGENT_SCREENSHOT_TIMEOUT=120' >>"$ENV_FILE"
grep -q '^PHONE_AGENT_FAIL_ON_TAKEOVER=' "$ENV_FILE" || echo 'PHONE_AGENT_FAIL_ON_TAKEOVER=false' >>"$ENV_FILE"
grep -q '^ADB_CONNECT_ADDRESS=' "$ENV_FILE" || echo 'ADB_CONNECT_ADDRESS=100.x.x.x:5555' >>"$ENV_FILE"
grep -q '^PHONE_AGENT_DEVICE_ID=' "$ENV_FILE" || echo 'PHONE_AGENT_DEVICE_ID=100.x.x.x:5555' >>"$ENV_FILE"

docker restart autoglm-mobile-copilot
sleep 4

echo "--- health ---"
curl -s http://127.0.0.1:8000/health
echo
echo "--- adb ---"
docker exec autoglm-mobile-copilot adb connect 100.x.x.x:5555 || true
docker exec autoglm-mobile-copilot adb devices
echo
echo "--- verify patch ---"
docker exec autoglm-mobile-copilot python -c "from phone_agent.config.apps import resolve_app_name; print('绯荤粺璁剧疆 ->', resolve_app_name('绯荤粺璁剧疆'))"
docker exec autoglm-mobile-copilot python -c "from phone_agent.actions.handler import ActionHandler; print('set_step_context:', hasattr(ActionHandler, 'set_step_context'))"

echo "Done. Test REAL task: 鎵撳紑璁剧疆"

