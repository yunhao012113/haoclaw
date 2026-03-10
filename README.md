# Haoclaw

Haoclaw is a self-hosted AI agent runtime derived from OpenClaw and repackaged for
simple setup, local deployment, and API-first usage.

## What Changed

- Brand, CLI, and local state paths are renamed to `haoclaw`
- Setup is simplified around provider + API key + optional base URL
- Repository community boilerplate from the upstream project is removed

## Quick Start

Install dependencies:

```bash
pnpm install
```

Run the simplified setup flow:

```bash
haoclaw setup --provider openai --api-key "$OPENAI_API_KEY"
```

For OpenAI-compatible endpoints:

```bash
haoclaw setup \
  --provider openai-compatible \
  --base-url http://127.0.0.1:11434/v1 \
  --model qwen2.5-coder \
  --api-key local-token
```

Start the gateway manually if needed:

```bash
haoclaw gateway
```

Check health:

```bash
haoclaw health
```

## Repository Scope

This repository is focused on:

- local and self-hosted agent runtime
- simplified onboarding
- model-provider configuration
- gateway, skills, and plugin execution

## Important Files

- `src/commands/setup.ts` - simplified first-run setup
- `src/cli/program/register.setup.ts` - CLI registration for setup
- `RELEASING.md` - release notes for maintainers
- `FIRST_PUSH.md` - first push instructions

## License

This repository retains the upstream MIT license. Review [`LICENSE`](LICENSE) before
redistributing builds or modified packages.
