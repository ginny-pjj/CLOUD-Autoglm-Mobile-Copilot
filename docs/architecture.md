# 云端版系统架构与实现逻辑

## 1. 总体调用链

```text
手机 App
  → 公网 HTTP
  → 云服务器 FastAPI Server
  → Open-AutoGLM main.py
  → PhoneAgent.run(task)
  → 截图 / 模型决策 / 远程 ADB 执行
  → 真实 Android 手机
```

本项目是云端远程版：后端和 Agent 运行在云服务器，本地电脑不参与日常任务执行。

## 2. 分层说明

| 层 | 位置 | 作用 |
| --- | --- | --- |
| 移动端 | `mobile-app/App.tsx` | 输入任务、配置云服务器地址、展示状态和 Trace |
| 云端 API | `server/main.py` | 提供任务接口，管理任务状态，连接远程 ADB，调用 Open-AutoGLM |
| Agent 入口 | `Open-AutoGLM/main.py` | 检查设备、键盘、模型 API，启动 PhoneAgent |
| Agent 主循环 | `Open-AutoGLM/phone_agent/agent.py` | Observe → Think → Act 多轮循环 |
| 动作执行 | `Open-AutoGLM/phone_agent/actions/handler.py` | 执行 Launch、Tap、Type、Swipe、Back、Home 等动作 |
| 设备控制 | `Open-AutoGLM/phone_agent/adb/` | 截图、输入、点击、滑动、远程设备连接 |
| 模型调用 | `Open-AutoGLM/phone_agent/model/client.py` | 调用智谱 `autoglm-phone` 模型 |

## 3. Real 模式执行流程

```text
POST /tasks { task, mode: real }
  → 检查 API Key 和云端运行环境
  → ensure_remote_adb() 根据 ADB_CONNECT_ADDRESS 连接手机
  → 可选唤醒手机、解锁、回桌面
  → 启动 Open-AutoGLM 子进程
  → Agent 获取手机截图
  → VLM 理解当前屏幕并输出动作
  → handler 调用远程 ADB 执行动作
  → 再次截图确认结果
  → 到达 finish 或超时后返回结果
```

## 4. 云端版运行条件

| 条件 | 说明 |
| --- | --- |
| 云服务器 | 运行 Docker 容器 |
| Docker / docker compose | 运行 FastAPI、Open-AutoGLM、adb |
| 手机无线调试 | 让云端 adb 能连接真实手机 |
| Tailscale | 推荐，用来打通云服务器与手机网络 |
| 智谱 API Key | 模型推理必需 |
| 手机 App | 访问云服务器公网地址 |

## 5. 关键工程补丁

- 云端自动 `adb connect`。
- 截图超时和压缩参数可配置。
- 非交互环境跳过 `Take_over` 的人工输入。
- 支持 UI Tree 辅助定位。
- 针对美团搜索增加专项快路径。

## 6. 展示时可讲的一句话

> 这个版本把 Open-AutoGLM Phone Agent 部署到云服务器上，手机 App 通过公网发任务，云端再通过 Tailscale 远程 ADB 控制真实手机，实现无需本地电脑参与的手机 Agent Demo。
