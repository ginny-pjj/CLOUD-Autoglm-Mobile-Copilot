# 云服务器部署指南（2核4G）

把本项目的 **FastAPI + Open-AutoGLM + ADB** 部署到云服务器，手机 App 通过公网 HTTP 访问，不再依赖本地电脑。

## 架构

```
手机 App  ──HTTP──►  云服务器:8000 (Docker)
                         ├── FastAPI
                         ├── Open-AutoGLM
                         ├── adb
                         └── 智谱 autoglm-phone API
                         │
                         └── adb connect ──► 你的 Android 手机（无线调试）
```

## 一、云服务器准备

### 1. 安全组 / 防火墙

放行 **TCP 8000**（或后续 Nginx 用 443）。

### 2. 安装 Docker（Ubuntu 22.04 示例）

```bash
sudo apt update
sudo apt install -y git docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
# 重新登录 SSH 一次
```

## 二、上传代码

### 方式 A：Git（推荐）

```bash
git clone <你的仓库地址> autoglm-mobile-work
cd autoglm-mobile-work
```

### 方式 B：本机打包上传

在 Windows 上打包 `Open-AutoGLM/`、`server/`、`Dockerfile`、`docker-compose.yml` 上传到云 `/root/autoglm-mobile-work/`。

## 三、配置环境变量

```bash
cd autoglm-mobile-work
cp server/.env.cloud.example server/.env.cloud
nano server/.env.cloud
```

填入：

```
BIGMODEL_API_KEY=你的智谱Key
```

## 四、启动服务

```bash
docker compose up -d --build
docker compose logs -f
```

验证：

```bash
curl http://127.0.0.1:8000/health
```

浏览器访问：`http://你的公网IP:8000/health`

应返回 `"status":"ok"` 且 `"version":"0.4.1"`。

## 五、手机无线 ADB 连到云（关键）

云上的 ADB 必须能连到你的手机，否则 REAL 模式无设备。

### 推荐：Tailscale（手机和云进同一虚拟网）

1. 云服务器安装 Tailscale：<https://tailscale.com/download/linux>
2. 手机安装 Tailscale App，登录同一账号
3. 手机：**设置 → 开发者选项 → 无线调试**（记下 IP:端口）
4. 在云服务器执行：

```bash
# 进入容器
docker exec -it autoglm-mobile-copilot bash

# 配对（Android 11+，只需一次）
adb pair 100.x.x.x:配对端口
adb connect 100.x.x.x:5555
adb devices
```

`100.x.x.x` 为手机 Tailscale IP。

### 备选：手机与云同 WiFi（仅 demo）

```bash
docker exec -it autoglm-mobile-copilot adb connect 192.168.x.x:5555
docker exec -it autoglm-mobile-copilot adb devices
```

## 六、手机 App 配置

1. 安装最新 `AutoGLM-Mobile-Copilot.apk`
2. **调试模式** 或后续版本的服务器地址填：

```
http://你的公网IP:8000
```

3. 点「连接测试」，应显示已连接
4. REAL 模式执行任务

> USB 模式下的 `adb reverse` 仅用于连本地电脑，**上云后不需要**。

## 七、常用命令

```bash
# 查看日志
docker compose logs -f

# 重启
docker compose restart

# 停止
docker compose down

# 容器内检查 ADB
docker exec -it autoglm-mobile-copilot adb devices
```

## 八、远程 REAL 优化（美团搜索等复杂任务）

v0.5 起支持远程 ADB 感知优化，需在 `server/.env.cloud` 配置：

```
ADB_CONNECT_ADDRESS=100.x.x.x:5555
PHONE_AGENT_SCREENSHOT_MAX_LONG_EDGE=720
PHONE_AGENT_SCREENSHOT_TIMEOUT=30
PHONE_AGENT_UI_TREE=true
TASK_TIMEOUT_SECONDS=360
```

- `exec-out screencap` + JPEG 压缩：减少跨 Tailscale 传输时间
- `PHONE_AGENT_UI_TREE`：每步附带 uiautomator 元素列表，辅助定位搜索框
- 容器启动时自动 `adb connect`（需填 `ADB_CONNECT_ADDRESS`）

**部署更新（Windows）：**

```powershell
D:\autoglm-mobile-work\scripts\deploy-remote-real.bat
ssh root@你的IP
cd /root/autoglm-mobile-work
docker compose up -d --build
```

**美团任务建议：**

1. 手动登录美团并停在首页，关掉弹窗
2. 任务写：`点击搜索框，搜索蜜雪冰城`（避免重复 Launch）
3. 确认 ADB Keyboard 已启用
4. 手机重启后：电脑 `adb tcpip 5555`，容器会自动 reconnect

## 九、常见问题

**`/health` 打不开**

- 检查安全组是否放行 8000
- `docker compose ps` 确认容器在运行

**REAL 模式无设备**

- 容器内 `adb devices` 是否为空
- 无线调试是否开启
- 云与手机网络是否互通（优先 Tailscale）

**ADB 重启后断开**

- 重新 `adb connect`
- 可考虑写启动脚本自动 connect

**HTTPS**

- 作业/demo 可先用 HTTP + 公网 IP
- 上线建议 Nginx + 域名 + Let's Encrypt

## 十、资源说明（2核4G / 200M）

- 同时 **1 个 REAL 任务 + 1 台手机** 足够
- 大模型在智谱云端，不占 CPU
- 不要在云上开 Android 模拟器
