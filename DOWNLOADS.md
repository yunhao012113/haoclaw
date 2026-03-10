# Haoclaw Downloads

这个页面只做一件事：让用户直接选系统并下载安装。

不要点 GitHub 的 `Code -> Download ZIP`。那个下载下来是源码，不是桌面应用。

如果你要一个统一的下载网站，启用 GitHub Pages 后用：

- `https://yunhao012113.github.io/haoclaw/`

启用方式：

1. 打开 GitHub 仓库 `Settings`
2. 进入 `Pages`
3. 在 `Build and deployment` 里选择 `Deploy from a branch`
4. Branch 选 `main`
5. Folder 选 `/docs`
6. 保存后等 1 到 3 分钟

## 直接选系统

### macOS

推荐先用 `PKG`，它更接近“一键安装”。

- [下载 Haoclaw PKG 安装程序](https://github.com/yunhao012113/haoclaw/releases/download/v2026.3.16/Haoclaw-2026.3.9.pkg)
- [下载 Haoclaw DMG 安装包](https://github.com/yunhao012113/haoclaw/releases/download/v2026.3.16/Haoclaw-2026.3.9.dmg)
- [查看最新版本发布页](https://github.com/yunhao012113/haoclaw/releases/latest)

安装说明：

1. 下载 `pkg` 或 `dmg`
2. 双击打开
3. 按提示安装，或把 `Haoclaw.app` 拖进“应用程序”
4. 安装完成后从启动台、“应用程序”或 Spotlight 打开

补充：

- macOS 不会默认把应用图标放到桌面
- Haoclaw 现在会按普通桌面应用方式启动，打开后直接显示主窗口

说明：

- 当前 release 已提供真正的桌面安装包，不是源码压缩包
- 如果 macOS 提示安全风险，这是因为当前还是公开测试版签名流程
- `PKG` 安装完成后会自动在桌面创建 `Haoclaw.app` 快捷方式
- 新版 macOS 安装包会同时支持 Intel 和 Apple Silicon

## Windows

Windows 原生桌面版已经接入安装包构建流程。

当前建议：

- 打开 [Latest Release](https://github.com/yunhao012113/haoclaw/releases/latest) 看是否已有最新 `Haoclaw-*-setup.exe`
- 如果当前 release 还没有 Windows 资产，请先走 WSL2 方案
- 说明文档在 [docs/platforms/windows.md](./docs/platforms/windows.md)

后续目标：

- 提供更完整的本地 Gateway 集成
- 继续补 `msi` 或自动更新

## Linux / WSL2

如果你不需要桌面壳，只想快速跑起来，直接用一条命令：

```bash
curl -fsSL https://raw.githubusercontent.com/yunhao012113/haoclaw/main/scripts/quick-install.sh | bash -s -- --provider openai --api-key "$OPENAI_API_KEY"
```

如果你是 OpenAI-compatible 接口：

```bash
curl -fsSL https://raw.githubusercontent.com/yunhao012113/haoclaw/main/scripts/quick-install.sh | bash -s -- \
  --provider openai-compatible \
  --base-url http://127.0.0.1:11434/v1 \
  --api-key local-token
```

## 给网站放下载按钮

如果你后面要做官网，按钮建议直接放这几个：

- `Download for macOS (PKG)`
- `Download for macOS (DMG)`
- `Download for Windows`
- `Run on Linux / WSL2`

对应链接：

- `https://github.com/yunhao012113/haoclaw/releases/latest`
- 或直接链接到具体资产
