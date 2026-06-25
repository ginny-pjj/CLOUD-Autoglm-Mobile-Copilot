FROM python:3.12-slim-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl unzip ca-certificates \
    && curl -fsSL https://dl.google.com/android/repository/platform-tools-latest-linux.zip -o /tmp/platform-tools.zip \
    && unzip -q /tmp/platform-tools.zip -d /tmp \
    && mv /tmp/platform-tools/adb /usr/bin/adb \
    && chmod +x /usr/bin/adb \
    && rm -rf /tmp/platform-tools /tmp/platform-tools.zip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Open-AutoGLM /app/Open-AutoGLM
COPY server /app/server

ENV PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    PIP_TRUSTED_HOST=mirrors.aliyun.com

RUN pip install --no-cache-dir -r /app/server/requirements.txt \
    && pip install --no-cache-dir -e /app/Open-AutoGLM

WORKDIR /app/server

ENV AUTOGLM_WORK_ROOT=/app \
    AUTOGLM_DIR=/app/Open-AutoGLM \
    ADB_PATH=/usr/bin/adb \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8 \
    PYTHONUTF8=1 \
    PHONE_AGENT_SCREENSHOT_MAX_LONG_EDGE=720 \
    PHONE_AGENT_SCREENSHOT_TIMEOUT=30 \
    PHONE_AGENT_UI_TREE=true

COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
