# AutoGLM Mobile Copilot Cloud

> 基于 [Open-AutoGLM](https://github.com/zai-org/Open-AutoGLM) 的**云端远程手机 AI Agent**（个人加分扩展）。  
> 手机 App 通过公网访问云服务器，FastAPI 调度 Phone Agent，经 Tailscale + 无线 ADB 远程控制真实 Android 手机。

**📌 给面试官：** 本仓库是**投入时间最多的工程进阶版**；作业主交付见 [USB 主仓库](https://github.com/ginny-pjj/USB-Autoglm-Mobile-Copilot)。  
**📖 系列总览：** [USB 主仓库 SERIES.md](https://github.com/ginny-pjj/USB-Autoglm-Mobile-Copilot/blob/main/SERIES.md)  
**📖 本仓库：** [作业对照与面试官导读](docs/作业对照与面试官导读.md) · [phone_agent 目录对照](docs/phone_agent-目录对照.md) · [云端部署](docs/cloud-deploy.md)

---

## 系列项目一览

| 版本 | GitHub 仓库 | 部署方式 | 定位 |
| --- | --- | --- | --- |
| USB v1（主入口） | [USB-Autoglm-Mobile-Copilot](https://github.com/ginny-pjj/USB-Autoglm-Mobile-Copilot) | USB + 电脑本地后端 | ✅ 作业主交付 |
| WiFi v1 | [WIFI-Autoglm-Mobile-Copilot](https://github.com/ginny-pjj/WIFI-Autoglm-Mobile-Copilot) | 同 WiFi 无线 ADB | ✅ 官方远程调试 |
| **Cloud（本仓库）** | [CLOUD-Autoglm-Mobile-Copilot](https://github.com/ginny-pjj/CLOUD-Autoglm-Mobile-Copilot) | 云 Docker + Tailscale | ⭐ **工程深度最高** |

> 云端版花费时间最长，解决了跨网远程控制、Docker 部署、远程截图/Take_over 等实际问题。面试建议：**USB 讲作业闭环，Cloud 讲工程能力。**

---

## 1. 项目定位
这是 **AutoGLM Mobile Copilot 的云服务器最终版**。

当前冻结基准：

> 云服务器远程控制真实手机，并完成美团搜索类任务。

本仓库只聚焦云端远程运行。USB 第一版见 [USB-Autoglm-Mobile-Copilot](https://github.com/ginny-pjj/USB-Autoglm-Mobile-Copilot)，WiFi 版见 [WIFI-Autoglm-Mobile-Copilot](https://github.com/ginny-pjj/WIFI-Autoglm-Mobile-Copilot)。

## 2. 项目背景

Open-AutoGLM 官方项目提供了 Phone Agent CLI，可以让大模型根据手机截图生成操作指令。本项目在官方能力上补齐了工程落地层：

- 手机 App 作为任务入口。
- FastAPI 后端封装 Agent CLI。
- Docker 部署到云服务器。
- 云端通过 Tailscale / 无线 ADB 控制真实手机。
- App 可查看结构化 Agent Trace。

## 3. 核心功能

| 功能 | 说明 |
| --- | --- |
| 手机 App 控制端 | 输入任务、配置服务器地址、选择 Mock/Real、查看 Trace |
| FastAPI 任务服务 | 提供 `/health`、`/devices`、`/tasks`、`/tasks/{id}/trace` |
| Open-AutoGLM 集成 | 后端通过 subprocess 调用 `Open-AutoGLM/main.py` |
| 云端 Docker 部署 | 服务器运行 FastAPI + Open-AutoGLM + adb |
| 远程 ADB 控制 | 推荐 Tailscale + 无线调试连接真实 Android 手机 |
| 结构化 Trace | 展示 Observe / Think / Action / Result |
| 远程场景优化 | 截图超时、截图压缩、UI Tree、非交互 Take_over 处理 |
| 美团任务优化 | 对美团搜索做专项快路径和干扰规避，提升演示稳定性 |

## 4. 系统架构

```text
Android App
  输入任务 / 展示 Trace
        ↓ HTTP
Cloud Server :8000 (Docker)
  FastAPI Server
        ↓ subprocess
Open-AutoGLM PhoneAgent
        ↓ Observe / Think / Act
phone_agent 内核
  screenshot → VLM → action parser → ADB handler
        ↓ remote ADB over Tailscale / wireless debugging
真实 Android 手机
```

建议补充图片：

```text
assets/architecture-cloud.png
assets/app-trace-cloud.png
assets/remote-meituan-result.png
```

## 5. 项目结构

```text
autoglm-mobile-copilot-cloud/
├── README.md
├── NOTICE.md
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .gitignore
├── ADBKeyboard.apk
├── Open-AutoGLM/              # 官方 Phone Agent 代码与云端补丁
├── server/                    # FastAPI 封装层
│   ├── main.py
│   ├── requirements.txt
│   ├── .env.cloud.example
│   └── .env.example
├── mobile-app/                # 手机控制端 App
├── docs/
│   ├── 作业对照与面试官导读.md
│   ├── architecture.md
│   ├── cloud-deploy.md
│   ├── demo-script.md
│   ├── faq.md
│   └── vibe-coding-log.md
├── assets/                    # 架构图、App 截图、结果截图
├── demo/                      # 云端远程演示视频
├── releases/                  # APK / Release 附件占位
└── scripts/                   # 云部署与容器运维脚本
```

## 6. 实现逻辑

```text
App POST /tasks
  → server/main.py 创建任务
  → 检查 BIGMODEL_API_KEY、Open-AutoGLM 路径、adb 环境
  → ensure_remote_adb() 连接手机无线 ADB
  → 可选 prepare_device：唤醒、解锁、回桌面、预启动目标 App
  → subprocess 启动 Open-AutoGLM/main.py
  → PhoneAgent.run(task)
      → 截图当前手机屏幕
      → 调用智谱 autoglm-phone 理解界面并生成动作
      → handler.py 执行 Launch / Tap / Type / Swipe 等动作
      → 再次截图进入下一轮
  → server 清洗日志为结构化 Trace
  → App 轮询任务状态并展示结果
```

一句话概括：

> 手机 App 发自然语言任务，云服务器上的 FastAPI 调度 Open-AutoGLM，Agent 看手机截图、让模型决策，再通过远程 ADB 操作真实手机。

## 7. 运行条件

| 条件 | 说明 |
| --- | --- |
| 云服务器 | 推荐 Ubuntu 22.04，2 核 4G 可跑单设备 demo |
| Docker / docker compose | 用于运行 FastAPI + Open-AutoGLM + adb |
| Android 手机 | 开启开发者选项与无线调试 |
| Tailscale | 推荐手机与云服务器加入同一虚拟网络 |
| 智谱 API Key | 用于调用 `autoglm-phone` |
| ADB Keyboard | 建议安装，用于提升中文输入稳定性 |
| 手机 App | 配置云服务器地址，如 `http://服务器IP:8000` |

本项目运行时 **不需要本地电脑一直开着**。本地电脑只在部署、维护、重新开启手机 TCP ADB 时可能需要。

## 8. 快速部署

### 8.1 准备云服务器

```bash
sudo apt update
sudo apt install -y git docker.io docker-compose-plugin
sudo systemctl enable --now docker
```

### 8.2 拉取项目

```bash
git clone <your-repo-url> autoglm-mobile-copilot-cloud
cd autoglm-mobile-copilot-cloud
```

### 8.3 配置环境变量

```bash
cp server/.env.cloud.example server/.env.cloud
nano server/.env.cloud
```

至少填写：

```text
BIGMODEL_API_KEY=你的智谱Key
ADB_CONNECT_ADDRESS=你的手机TailscaleIP:5555
PHONE_AGENT_DEVICE_ID=你的手机TailscaleIP:5555
```

### 8.4 启动服务

```bash
docker compose up -d --build
docker compose logs -f
```

健康检查：

```bash
curl http://127.0.0.1:8000/health
```

公网访问：

```text
http://服务器IP:8000/health
```

### 8.5 连接手机远程 ADB

进入容器：

```bash
docker exec -it autoglm-mobile-copilot bash
adb connect 你的手机TailscaleIP:5555
adb devices
```

如果设备显示为 `device`，说明云端可以控制手机。

## 9. App 使用方式

手机 App 中填写：

```text
http://服务器IP:8000
```

推荐演示任务：

```text
打开美团搜索蜜雪冰城
```

执行流程：

1. 点击连接测试。
2. 选择 Real 模式。
3. 输入任务。
4. 点击开始执行。
5. 观察真实手机动作与 App Trace。

## 10. Demo Video（演示视频）

本项目包含云端远程控制真实手机的录屏演示，视频托管在 **GitHub Releases**。

- **Cloud Demo：** [观看 / 下载演示视频](https://github.com/ginny-pjj/CLOUD-Autoglm-Mobile-Copilot/releases)

视频内容包含：

- 云服务器 `/health` 正常
- 手机 App 通过公网提交任务
- 云端远程 ADB 控制真实手机（推荐任务：打开美团搜索蜜雪冰城）
- Agent Trace 与最终结果

**全系列 Demo：** [USB 主仓库 SERIES.md](https://github.com/ginny-pjj/USB-Autoglm-Mobile-Copilot/blob/main/SERIES.md#demo-演示视频)

<!-- 上传 Release 后改为具体链接，例如：
- [Cloud Demo](https://github.com/ginny-pjj/CLOUD-Autoglm-Mobile-Copilot/releases/download/v1.0-demo/demo_remote_meituan.mp4)
-->

## 11. phone_agent 目录对照

→ **[docs/phone_agent-目录对照.md](docs/phone_agent-目录对照.md)**（Cloud 版在 screenshot / handler 等处有远程场景补丁说明）

## 12. 为什么小红书任务比美团慢

小红书在本项目中的执行速度明显慢于美团，原因主要有两点：

1. 美团搜索做了专项优化，包括搜索快路径、UI 树辅助定位搜索框、对地址栏和问小团等干扰项的规避，因此减少了多轮截图和模型判断。
2. 小红书主要走通用 Agent 链路，每一步都需要“截图 → 模型理解 → ADB 执行 → 再截图确认”。云端远程 ADB 还会增加截图传输延迟，因此页面切换越多，累计耗时越明显。

## 13. 本项目优化点

- 将 Open-AutoGLM CLI 封装为云端 FastAPI 服务。
- 设计手机 App 作为 Agent 控制入口。
- 增加任务状态、日志和结构化 Trace。
- 使用 Docker 部署云端服务。
- 支持 Tailscale + 远程 ADB 控制真实手机。
- 处理远程截图超时、非交互 Take_over、键盘检查等云端问题。
- 针对美团搜索增加专项演示优化。

## 14. 后续可改进方向

- WebSocket 推送 Trace，替代轮询。
- 增加更多 App 的 Skill 配置。
- 增加失败截图和任务回放。
- 提供 HTTPS、鉴权和访问控制。
- 支持多设备管理与任务队列。

## 15. 对照 Open-AutoGLM 作业要求

| 类别 | 说明 |
| --- | --- |
| 作业必做（Agent 内核、ADB、智谱 API） | ✅ 完整保留于 `Open-AutoGLM/phone_agent/` |
| 作业选做（官方 WiFi 远程 ADB） | ✅ 本仓库用 Tailscale 扩展到跨网 |
| 作业未要求（Docker 云部署、公网 App） | ⭐ **本仓库核心价值** |

完整对照、面试话术、三版本讲法 → **[docs/作业对照与面试官导读.md](docs/作业对照与面试官导读.md)**

## 16. 致谢

本项目基于 [zai-org/Open-AutoGLM](https://github.com/zai-org/Open-AutoGLM) 进行工程封装和云端远程部署改造。请遵守上游项目的 License 与引用要求。

请勿提交真实 API Key、服务器 IP、Tailscale 私有地址或包含隐私信息的录屏。
