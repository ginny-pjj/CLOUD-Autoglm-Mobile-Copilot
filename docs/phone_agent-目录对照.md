# phone_agent 目录对照（对齐 Open-AutoGLM 官方结构）

> 官方仓库：[zai-org/Open-AutoGLM](https://github.com/zai-org/Open-AutoGLM)  
> 本系列三个版本共用同一套 `Open-AutoGLM/phone_agent/` 内核，未重写 Agent 核心。

---

## 1. 官方标准结构（作业要求）

见 [Open-AutoGLM README](https://github.com/zai-org/Open-AutoGLM) 中的 `phone_agent/` 树形结构：`agent.py` · `adb/` · `actions/` · `config/` · `model/`。

**一步流程：** 截图 → VLM 决策 → handler 执行 → ADB 操作 → 循环。

---

## 2. 本项目的目录位置

```text
Open-AutoGLM/phone_agent/     # 官方 Agent 内核
server/main.py                # FastAPI + 远程 ADB + 美团快路径
mobile-app/                   # Android 控制端
```

---

## 3. Cloud 版在官方结构上的补丁（工程亮点）

| 文件 | Cloud 版额外处理 |
| --- | --- |
| `adb/screenshot.py` | 远程截图超时、压缩、debug 落盘 |
| `actions/handler.py` | 非交互环境自动跳过 Take_over（避免 EOF） |
| `adb/connection.py` | 容器内 `adb connect` Tailscale 地址 |
| `config/apps.py` | 应用别名（如「系统设置」→「设置」） |
| `server/main.py` | `ensure_remote_adb()`、美团搜索快路径 |

---

## 4. 三层调用关系

```text
App → 云 FastAPI → Open-AutoGLM/main.py → phone_agent/ → 远程 ADB → 手机
```

系列总览 → [USB 主仓库 SERIES.md](https://github.com/ginny-pjj/USB-Autoglm-Mobile-Copilot/blob/main/SERIES.md)

完整对照表（含官方文件树）→ [USB 仓库完整版](https://github.com/ginny-pjj/USB-Autoglm-Mobile-Copilot/blob/main/docs/phone_agent-目录对照.md)
