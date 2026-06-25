#!/bin/bash
# Run on cloud server (SSH as root): bash scripts/fix-docker-registry.sh
set -eu

echo "=== 1. DNS (fix Tailscale/DNS hijack) ==="
if command -v tailscale >/dev/null 2>&1; then
  tailscale set --accept-dns=false 2>/dev/null || true
  echo "Tailscale accept-dns=false"
fi
printf 'nameserver 223.5.5.5\nnameserver 114.114.114.114\nnameserver 8.8.8.8\n' >/etc/resolv.conf
echo "resolv.conf updated"
cat /etc/resolv.conf

echo ""
echo "=== 2. Docker registry mirrors ==="
mkdir -p /etc/docker
cat >/etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.1panel.live",
    "https://hub.rat.dev"
  ],
  "dns": ["223.5.5.5", "114.114.114.114", "8.8.8.8"],
  "max-concurrent-downloads": 3
}
EOF
cat /etc/docker/daemon.json

systemctl daemon-reload
systemctl restart docker
sleep 3
echo "Docker restarted"

echo ""
echo "=== 3. Test pull (60s timeout each) ==="
for img in \
  "python:3.12-slim-bookworm" \
  "registry.cn-hangzhou.aliyuncs.com/library/python:3.12-slim-bookworm"
do
  echo "--- trying: $img ---"
  if timeout 90 docker pull "$img"; then
    echo "OK: $img"
    exit 0
  fi
  echo "FAILED: $img"
done

echo ""
echo "All pulls failed. Try hot-patch without rebuild:"
echo "  cd /root/autoglm-mobile-work && bash scripts/hot-patch-container.sh"
