#!/bin/bash
# Apply latest code into running container WITHOUT docker build (when pull fails)
set -eu
cd /root/autoglm-mobile-work
C=autoglm-mobile-copilot

echo "Hot-patching $C ..."
docker cp Open-AutoGLM/phone_agent/agent.py "$C:/app/Open-AutoGLM/phone_agent/agent.py"
docker cp Open-AutoGLM/phone_agent/actions/handler.py "$C:/app/Open-AutoGLM/phone_agent/actions/handler.py"
docker cp Open-AutoGLM/phone_agent/adb/ui_tree.py "$C:/app/Open-AutoGLM/phone_agent/adb/ui_tree.py"
docker cp Open-AutoGLM/phone_agent/adb/screenshot.py "$C:/app/Open-AutoGLM/phone_agent/adb/screenshot.py"
docker cp Open-AutoGLM/phone_agent/adb/input.py "$C:/app/Open-AutoGLM/phone_agent/adb/input.py"
docker cp Open-AutoGLM/phone_agent/adb/device.py "$C:/app/Open-AutoGLM/phone_agent/adb/device.py"
docker cp Open-AutoGLM/phone_agent/config/apps.py "$C:/app/Open-AutoGLM/phone_agent/config/apps.py"
docker cp Open-AutoGLM/phone_agent/model/client.py "$C:/app/Open-AutoGLM/phone_agent/model/client.py"
docker cp Open-AutoGLM/phone_agent/model/__init__.py "$C:/app/Open-AutoGLM/phone_agent/model/__init__.py"
docker cp Open-AutoGLM/main.py "$C:/app/Open-AutoGLM/main.py"
docker cp server/main.py "$C:/app/server/main.py"
docker compose restart
sleep 5
docker compose ps
docker exec "$C" adb connect "${ADB_CONNECT_ADDRESS:-100.x.x.x:5555}" || true
docker exec "$C" adb devices -l || true
echo "Done."

