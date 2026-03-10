# Haoclaw

Haoclaw 是一个面向个人和小团队的自托管 AI 代理运行时。
它强调三件事：简单接入、可本地部署、按你的 API 与规则运行。

你可以把它理解成一个统一的 AI 网关和代理执行层：

- 用一个命令完成初始化
- 接入 OpenAI 或兼容接口
- 启动本地 gateway
- 让 agent、skills、插件和多种通道在同一套运行时下工作

## 为什么是 Haoclaw

很多 AI agent 项目能跑，但真正落地时往往有几个问题：

- 首次配置长且杂
- 模型、代理、网关配置分散
- 想改一个 provider 就要翻很多文档
- 明明只是想接 API，却被一堆不必要的集成功能打断

Haoclaw 的目标就是把这些路径压平：

- 默认走 API-first 配置
- 优先支持本地、自托管和可控部署
- 保留 gateway、skills、plugin 能力
- 把首次可用路径收敛到最少命令

## 核心能力

- 本地 AI gateway 运行时
- 简化后的 `haoclaw setup` 初始化流程
- OpenAI 与 OpenAI-compatible provider 接入
- agent、skills、插件统一运行
- 可扩展的多通道消息与集成架构
- 可继续保留高级能力，但默认先走简单路径

## 接口接入方式

现在推荐把 Haoclaw 当成“填 API 就能连”的运行时来使用。
常见接口路径如下：

- OpenAI
- Anthropic
- OpenRouter
- Gemini
- OpenAI-compatible 接口
- Anthropic-compatible 接口

对于大多数用户，优先用这两种：

- 官方 provider：只填 `provider + api-key`
- 兼容接口：填 `base-url + api-key`，能自动识别模型时就不再手填 `model`

## 快速开始

### 桌面客户端下载

如果你想直接下载桌面客户端，而不是从源码运行，推荐用 GitHub Releases：

- 打开仓库的 `Releases`
- 下载最新的 `Haoclaw-*.dmg`
- 如果你更习惯手动解压，也可以下载 `Haoclaw-*.zip`

仓库已经支持 `v*` 标签自动打包 macOS 桌面客户端并上传到 Release 资产。
如果你要在官网放下载按钮，直接链接到 GitHub Release 页面或具体的 `dmg` 资产就可以。

```bash
cd /Users/yunhao/Desktop/haoclaw-src
git tag v2026.3.10
git push origin v2026.3.10
```

### 环境要求

- Node.js `>= 22.12.0`
- `pnpm >= 10`

### 仓库一键部署

如果你是从仓库直接运行，最简单的是这一条：

```bash
bash scripts/deploy.sh --provider openai --api-key "$OPENAI_API_KEY"
```

如果你使用 OpenAI-compatible 接口：

```bash
bash scripts/deploy.sh \
  --provider openai-compatible \
  --base-url http://127.0.0.1:11434/v1 \
  --api-key local-token
```

这个脚本会自动做两件事：

- 缺少依赖时自动执行 `pnpm install`
- 然后直接调用 `haoclaw deploy`

### GitHub 一键安装部署

如果你想要像官网那样“一条终端命令直接部署”，可以直接运行：

```bash
curl -fsSL https://raw.githubusercontent.com/yunhao012113/haoclaw/main/scripts/quick-install.sh | bash -s -- --provider openai --api-key "$OPENAI_API_KEY"
```

OpenAI-compatible 接口：

```bash
curl -fsSL https://raw.githubusercontent.com/yunhao012113/haoclaw/main/scripts/quick-install.sh | bash -s -- \
  --provider openai-compatible \
  --base-url http://127.0.0.1:11434/v1 \
  --api-key local-token
```

这条命令会自动：

- clone 或更新 GitHub 仓库
- 安装依赖
- 执行 `haoclaw deploy`
- 启动 gateway 并做健康检查
- 生成全局 `haoclaw` 启动命令
- 输出本地访问地址与后续可执行命令

### 安装依赖

```bash
pnpm install
```

### 一键初始化

如果你使用 OpenAI：

```bash
haoclaw setup --provider openai --api-key "$OPENAI_API_KEY"
```

如果你使用 OpenAI 兼容接口，例如 Ollama、LiteLLM、vLLM 或自建代理：

```bash
haoclaw setup \
  --provider openai-compatible \
  --base-url http://127.0.0.1:11434/v1 \
  --api-key local-token
```

如果接口没有开放 `/models`，再补上 `--model`：

```bash
haoclaw setup \
  --provider openai-compatible \
  --base-url http://127.0.0.1:11434/v1 \
  --model qwen2.5-coder \
  --api-key local-token
```

这个初始化流程会尽量帮你完成：

- 写入最小可用配置
- 使用本地 gateway 模式
- 跳过不必要的复杂交互
- 对 OpenAI-compatible 接口自动探测可用模型
- 自动启动 gateway
- 自动执行健康检查

## 常用命令

一键部署：

```bash
haoclaw deploy --provider openai --api-key "$OPENAI_API_KEY"
```

启动 gateway：

```bash
haoclaw gateway
```

检查运行状态：

```bash
haoclaw health
```

发送一条测试消息：

```bash
haoclaw agent --agent main --message "你好"
```

查看帮助：

```bash
haoclaw --help
haoclaw setup --help
```

## 当前推荐用法

如果你只是想尽快跑起来，建议按这个顺序：

1. 安装依赖
2. 执行 `haoclaw setup`
3. 确认 `haoclaw health`
4. 再按需要启用 skills、插件或其他集成

这样能避免一开始就陷入复杂配置。

## 支持的接入方向

Haoclaw 的仓库里保留了完整运行时结构，所以后续你可以继续往下扩展：

- provider 切换
- skills 加载
- 本地工作区 agent
- 插件式通道接入
- web / gateway / automation 扩展

如果你的目标只是做一个稳定可用的本地 agent，完全可以只使用：

- `setup`
- `gateway`
- `agent`

不需要先碰所有高级模块。

## 目录说明

- `src/commands/setup.ts`
  简化初始化逻辑的核心入口
- `src/cli/program/register.setup.ts`
  `setup` 命令注册与参数定义
- `skills/`
  内置技能目录
- `extensions/`
  扩展与插件能力
- `docs/`
  说明文档
- `RELEASING.md`
  仓库发版说明
- `FIRST_PUSH.md`
  首次推送说明

## 适合谁

Haoclaw 更适合这几类使用场景：

- 想要一个能自托管的 AI agent 运行时
- 想快速接自己的 API key，而不是先研究一大堆配置
- 想逐步扩展 skills、插件和网关能力
- 想保留源码级可控性

## 当前仓库重点

这个仓库当前重点不是“做一个展示型社区首页”，而是：

- 先让项目能跑
- 先让接入足够简单
- 先把 GitHub 仓库整理成可维护、可发布、可继续迭代的状态

## 许可证

本仓库沿用 MIT 许可证。
发布、分发或二次修改前，请先查看 [`LICENSE`](LICENSE)。
