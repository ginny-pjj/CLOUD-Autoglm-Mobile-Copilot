# One-shot deploy for remote REAL patches (single password prompt)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Host_ = "your-server-ip"
$Remote = "/root/autoglm-mobile-work"
$Archive = Join-Path $env:TEMP "autoglm-remote-real-patch.tar.gz"

Push-Location $Root
try {
    Write-Host "Packing changed files..."
    tar -czf $Archive `
        Open-AutoGLM/phone_agent/adb/screenshot.py `
        Open-AutoGLM/phone_agent/adb/ui_tree.py `
        Open-AutoGLM/phone_agent/adb/device.py `
        Open-AutoGLM/phone_agent/adb/input.py `
        Open-AutoGLM/phone_agent/actions/handler.py `
        Open-AutoGLM/phone_agent/adb/__init__.py `
        Open-AutoGLM/phone_agent/agent.py `
        Open-AutoGLM/phone_agent/device_factory.py `
        Open-AutoGLM/main.py `
        Open-AutoGLM/phone_agent/model/client.py `
        Dockerfile `
        docker-compose.yml `
        scripts/docker-entrypoint.sh `
        server/.env.cloud.example `
        server/main.py `
        docs/cloud-deploy.md

    Write-Host "Uploading to ${Host_} (enter root password once)..."
    scp $Archive "root@${Host_}:/root/autoglm-remote-real-patch.tar.gz"

    Write-Host ""
    Write-Host "Extracting and rebuilding on server (enter root password once more)..."
    ssh "root@${Host_}" @"
set -e
cd $Remote
tar -xzf /root/autoglm-remote-real-patch.tar.gz
chmod +x scripts/docker-entrypoint.sh
grep -q '^ADB_CONNECT_ADDRESS=' server/.env.cloud 2>/dev/null || echo 'ADB_CONNECT_ADDRESS=100.x.x.x:5555' >> server/.env.cloud
grep -q '^PHONE_AGENT_UI_TREE=' server/.env.cloud 2>/dev/null || echo 'PHONE_AGENT_UI_TREE=true' >> server/.env.cloud
grep -q '^PHONE_AGENT_SCREENSHOT_TIMEOUT=' server/.env.cloud 2>/dev/null || echo 'PHONE_AGENT_SCREENSHOT_TIMEOUT=30' >> server/.env.cloud
grep -q '^PHONE_AGENT_SCREENSHOT_MAX_LONG_EDGE=' server/.env.cloud 2>/dev/null || echo 'PHONE_AGENT_SCREENSHOT_MAX_LONG_EDGE=720' >> server/.env.cloud
grep -q '^PHONE_AGENT_ADB_CMD_TIMEOUT=' server/.env.cloud 2>/dev/null || echo 'PHONE_AGENT_ADB_CMD_TIMEOUT=45' >> server/.env.cloud
grep -q '^PHONE_AGENT_SKIP_KEYBOARD_CHECK=' server/.env.cloud 2>/dev/null || echo 'PHONE_AGENT_SKIP_KEYBOARD_CHECK=true' >> server/.env.cloud
grep -q '^PHONE_AGENT_DEVICE_ID=' server/.env.cloud 2>/dev/null || echo 'PHONE_AGENT_DEVICE_ID=100.x.x.x:5555' >> server/.env.cloud
grep -q '^PHONE_AGENT_KEEP_ADB_KEYBOARD=' server/.env.cloud 2>/dev/null || echo 'PHONE_AGENT_KEEP_ADB_KEYBOARD=true' >> server/.env.cloud
grep -q '^PHONE_AGENT_FAIL_ON_TAKEOVER=' server/.env.cloud 2>/dev/null || echo 'PHONE_AGENT_FAIL_ON_TAKEOVER=true' >> server/.env.cloud
grep -q '^PHONE_AGENT_CONTINUE_ON_SCREENSHOT_TAKEOVER=' server/.env.cloud 2>/dev/null || echo 'PHONE_AGENT_CONTINUE_ON_SCREENSHOT_TAKEOVER=true' >> server/.env.cloud
grep -q '^AUTOGLM_DISABLE_FAST_PATH=' server/.env.cloud 2>/dev/null || echo 'AUTOGLM_DISABLE_FAST_PATH=false' >> server/.env.cloud
grep -q '^PHONE_AGENT_TAP_DELAY=' server/.env.cloud 2>/dev/null || echo 'PHONE_AGENT_TAP_DELAY=2' >> server/.env.cloud
grep -q '^PHONE_AGENT_LAUNCH_DELAY=' server/.env.cloud 2>/dev/null || echo 'PHONE_AGENT_LAUNCH_DELAY=4' >> server/.env.cloud
grep -q '^PHONE_AGENT_TEXT_INPUT_DELAY=' server/.env.cloud 2>/dev/null || echo 'PHONE_AGENT_TEXT_INPUT_DELAY=2' >> server/.env.cloud
grep -q '^TASK_TIMEOUT_SECONDS=' server/.env.cloud 2>/dev/null || echo 'TASK_TIMEOUT_SECONDS=360' >> server/.env.cloud
docker compose up -d --build
docker compose ps
docker compose logs --tail 15
"@

    Write-Host ""
    Write-Host "Done. Check logs above for [entrypoint] Connecting ADB..."
}
finally {
    Pop-Location
    if (Test-Path $Archive) { Remove-Item $Archive -Force }
}


