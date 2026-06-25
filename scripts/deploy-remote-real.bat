@echo off
setlocal

set HOST=your-server-ip
set REMOTE=/root/autoglm-mobile-work
set ROOT=%~dp0..

echo Uploading remote REAL patches to %HOST% ...

scp "%ROOT%\Open-AutoGLM\phone_agent\adb\screenshot.py" root@%HOST%:%REMOTE%/Open-AutoGLM/phone_agent/adb/screenshot.py
scp "%ROOT%\Open-AutoGLM\phone_agent\adb\ui_tree.py" root@%HOST%:%REMOTE%/Open-AutoGLM/phone_agent/adb/ui_tree.py
scp "%ROOT%\Open-AutoGLM\phone_agent\adb\__init__.py" root@%HOST%:%REMOTE%/Open-AutoGLM/phone_agent/adb/__init__.py
scp "%ROOT%\Open-AutoGLM\phone_agent\agent.py" root@%HOST%:%REMOTE%/Open-AutoGLM/phone_agent/agent.py
scp "%ROOT%\Open-AutoGLM\phone_agent\device_factory.py" root@%HOST%:%REMOTE%/Open-AutoGLM/phone_agent/device_factory.py
scp "%ROOT%\Dockerfile" root@%HOST%:%REMOTE%/Dockerfile
scp "%ROOT%\scripts\docker-entrypoint.sh" root@%HOST%:%REMOTE%/scripts/docker-entrypoint.sh
scp "%ROOT%\server\.env.cloud.example" root@%HOST%:%REMOTE%/server/.env.cloud.example

echo.
echo Done. Now SSH in and run:
echo   cd %REMOTE%
echo   # add ADB_CONNECT_ADDRESS=your-phone-tailscale-ip:5555 to server/.env.cloud
echo   docker compose up -d --build

endlocal

