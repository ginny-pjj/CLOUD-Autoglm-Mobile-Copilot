@echo off
setlocal
set HOST=your-server-ip
set ROOT=D:\autoglm-mobile-work
set REMOTE=/root/autoglm-mobile-work

echo ========================================
echo Upload patched files to %HOST%
echo (enter root password when prompted)
echo ========================================
echo.

scp "%ROOT%\Open-AutoGLM\phone_agent\agent.py" root@%HOST%:%REMOTE%/Open-AutoGLM/phone_agent/agent.py
scp "%ROOT%\Open-AutoGLM\phone_agent\config\apps.py" root@%HOST%:%REMOTE%/Open-AutoGLM/phone_agent/config/apps.py
scp "%ROOT%\Open-AutoGLM\phone_agent\adb\device.py" root@%HOST%:%REMOTE%/Open-AutoGLM/phone_agent/adb/device.py
scp "%ROOT%\Open-AutoGLM\phone_agent\actions\handler.py" root@%HOST%:%REMOTE%/Open-AutoGLM/phone_agent/actions/handler.py
scp "%ROOT%\Open-AutoGLM\phone_agent\adb\screenshot.py" root@%HOST%:%REMOTE%/Open-AutoGLM/phone_agent/adb/screenshot.py
scp "%ROOT%\server\main.py" root@%HOST%:%REMOTE%/server/main.py
scp "%ROOT%\scripts\cloud-restart.sh" root@%HOST%:%REMOTE%/scripts/cloud-restart.sh

echo.
echo ========================================
echo Upload done. Now SSH in and run:
echo   ssh root@%HOST%
echo   bash /root/autoglm-mobile-work/scripts/cloud-restart.sh
echo ========================================
pause

