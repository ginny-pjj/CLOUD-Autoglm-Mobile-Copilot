# 云端版演示脚本

## 1. 演示目标

展示手机 App 通过公网调用云服务器上的 AutoGLM Agent，并远程控制真实 Android 手机完成美团搜索任务。

推荐任务：

```text
打开美团搜索蜜雪冰城
```

## 2. 演示前准备

1. 云服务器 Docker 服务正在运行。
2. `http://服务器IP:8000/health` 返回正常。
3. 手机开启 Tailscale。
4. 手机开启无线调试或 TCP ADB。
5. 云容器内 `adb devices` 能看到手机。
6. 手机 App 服务器地址填写 `http://服务器IP:8000`。
7. 美团已登录，尽量关闭弹窗。

## 3. 录屏建议

建议视频文件名：

```text
demo/demo_remote_meituan.mp4
```

录屏画面建议包含：

1. App 输入任务。
2. 点击连接测试。
3. 选择 Real 模式。
4. 点击开始执行。
5. 展示真实手机被自动操作。
6. 展示 App Trace 和最终结果。

## 4. 答辩讲解顺序

### 项目一句话

这是一个基于 Open-AutoGLM 的云端手机 AI Agent 项目，用户在 App 里输入任务，云服务器通过大模型看截图并用远程 ADB 操作真实手机。

### 架构说明

```text
App → 云服务器 FastAPI → Open-AutoGLM PhoneAgent → Tailscale / 远程 ADB → Android 手机
```

### 关键亮点

- 从 CLI 扩展成移动端可调用的云端服务。
- Docker 部署，手机 App 不依赖本地电脑。
- 使用 Tailscale 解决云端访问真实手机的问题。
- 结构化 Trace 展示 Agent 的观察、思考和动作。
- 对美团搜索做专项优化，提高演示稳定性。

## 5. 视频说明文字

> 本视频展示 AutoGLM Mobile Copilot 云端版。手机 App 通过公网访问云服务器 FastAPI 服务，后端调用 Open-AutoGLM Phone Agent，并通过 Tailscale 远程 ADB 控制真实 Android 手机完成“打开美团搜索蜜雪冰城”的任务。
