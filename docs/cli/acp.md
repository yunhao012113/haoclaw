---
summary: "Run the ACP bridge for IDE integrations"
read_when:
  - Setting up ACP-based IDE integrations
  - Debugging ACP session routing to the Gateway
title: "acp"
---

# acp

Run the [Agent Client Protocol (ACP)](https://agentclientprotocol.com/) bridge that talks to a Haoclaw Gateway.

This command speaks ACP over stdio for IDEs and forwards prompts to the Gateway
over WebSocket. It keeps ACP sessions mapped to Gateway session keys.

## Usage

```bash
haoclaw acp

# Remote Gateway
haoclaw acp --url wss://gateway-host:18789 --token <token>

# Remote Gateway (token from file)
haoclaw acp --url wss://gateway-host:18789 --token-file ~/.haoclaw/gateway.token

# Attach to an existing session key
haoclaw acp --session agent:main:main

# Attach by label (must already exist)
haoclaw acp --session-label "support inbox"

# Reset the session key before the first prompt
haoclaw acp --session agent:main:main --reset-session
```

## ACP client (debug)

Use the built-in ACP client to sanity-check the bridge without an IDE.
It spawns the ACP bridge and lets you type prompts interactively.

```bash
haoclaw acp client

# Point the spawned bridge at a remote Gateway
haoclaw acp client --server-args --url wss://gateway-host:18789 --token-file ~/.haoclaw/gateway.token

# Override the server command (default: haoclaw)
haoclaw acp client --server "node" --server-args haoclaw.mjs acp --url ws://127.0.0.1:19001
```

Permission model (client debug mode):

- Auto-approval is allowlist-based and only applies to trusted core tool IDs.
- `read` auto-approval is scoped to the current working directory (`--cwd` when set).
- Unknown/non-core tool names, out-of-scope reads, and dangerous tools always require explicit prompt approval.
- Server-provided `toolCall.kind` is treated as untrusted metadata (not an authorization source).

## How to use this

Use ACP when an IDE (or other client) speaks Agent Client Protocol and you want
it to drive a Haoclaw Gateway session.

1. Ensure the Gateway is running (local or remote).
2. Configure the Gateway target (config or flags).
3. Point your IDE to run `haoclaw acp` over stdio.

Example config (persisted):

```bash
haoclaw config set gateway.remote.url wss://gateway-host:18789
haoclaw config set gateway.remote.token <token>
```

Example direct run (no config write):

```bash
haoclaw acp --url wss://gateway-host:18789 --token <token>
# preferred for local process safety
haoclaw acp --url wss://gateway-host:18789 --token-file ~/.haoclaw/gateway.token
```

## Selecting agents

ACP does not pick agents directly. It routes by the Gateway session key.

Use agent-scoped session keys to target a specific agent:

```bash
haoclaw acp --session agent:main:main
haoclaw acp --session agent:design:main
haoclaw acp --session agent:qa:bug-123
```

Each ACP session maps to a single Gateway session key. One agent can have many
sessions; ACP defaults to an isolated `acp:<uuid>` session unless you override
the key or label.

## Use from `acpx` (Codex, Claude, other ACP clients)

If you want a coding agent such as Codex or Claude Code to talk to your
Haoclaw bot over ACP, use `acpx` with its built-in `haoclaw` target.

Typical flow:

1. Run the Gateway and make sure the ACP bridge can reach it.
2. Point `acpx haoclaw` at `haoclaw acp`.
3. Target the Haoclaw session key you want the coding agent to use.

Examples:

```bash
# One-shot request into your default Haoclaw ACP session
acpx haoclaw exec "Summarize the active Haoclaw session state."

# Persistent named session for follow-up turns
acpx haoclaw sessions ensure --name codex-bridge
acpx haoclaw -s codex-bridge --cwd /path/to/repo \
  "Ask my Haoclaw work agent for recent context relevant to this repo."
```

If you want `acpx haoclaw` to target a specific Gateway and session key every
time, override the `haoclaw` agent command in `~/.acpx/config.json`:

```json
{
  "agents": {
    "haoclaw": {
      "command": "env HAOCLAW_HIDE_BANNER=1 HAOCLAW_SUPPRESS_NOTES=1 haoclaw acp --url ws://127.0.0.1:18789 --token-file ~/.haoclaw/gateway.token --session agent:main:main"
    }
  }
}
```

For a repo-local Haoclaw checkout, use the direct CLI entrypoint instead of the
dev runner so the ACP stream stays clean. For example:

```bash
env HAOCLAW_HIDE_BANNER=1 HAOCLAW_SUPPRESS_NOTES=1 node haoclaw.mjs acp ...
```

This is the easiest way to let Codex, Claude Code, or another ACP-aware client
pull contextual information from an Haoclaw agent without scraping a terminal.

## Zed editor setup

Add a custom ACP agent in `~/.config/zed/settings.json` (or use Zed’s Settings UI):

```json
{
  "agent_servers": {
    "Haoclaw ACP": {
      "type": "custom",
      "command": "haoclaw",
      "args": ["acp"],
      "env": {}
    }
  }
}
```

To target a specific Gateway or agent:

```json
{
  "agent_servers": {
    "Haoclaw ACP": {
      "type": "custom",
      "command": "haoclaw",
      "args": [
        "acp",
        "--url",
        "wss://gateway-host:18789",
        "--token",
        "<token>",
        "--session",
        "agent:design:main"
      ],
      "env": {}
    }
  }
}
```

In Zed, open the Agent panel and select “Haoclaw ACP” to start a thread.

## Session mapping

By default, ACP sessions get an isolated Gateway session key with an `acp:` prefix.
To reuse a known session, pass a session key or label:

- `--session <key>`: use a specific Gateway session key.
- `--session-label <label>`: resolve an existing session by label.
- `--reset-session`: mint a fresh session id for that key (same key, new transcript).

If your ACP client supports metadata, you can override per session:

```json
{
  "_meta": {
    "sessionKey": "agent:main:main",
    "sessionLabel": "support inbox",
    "resetSession": true
  }
}
```

Learn more about session keys at [/concepts/session](/concepts/session).

## Options

- `--url <url>`: Gateway WebSocket URL (defaults to gateway.remote.url when configured).
- `--token <token>`: Gateway auth token.
- `--token-file <path>`: read Gateway auth token from file.
- `--password <password>`: Gateway auth password.
- `--password-file <path>`: read Gateway auth password from file.
- `--session <key>`: default session key.
- `--session-label <label>`: default session label to resolve.
- `--require-existing`: fail if the session key/label does not exist.
- `--reset-session`: reset the session key before first use.
- `--no-prefix-cwd`: do not prefix prompts with the working directory.
- `--verbose, -v`: verbose logging to stderr.

Security note:

- `--token` and `--password` can be visible in local process listings on some systems.
- Prefer `--token-file`/`--password-file` or environment variables (`HAOCLAW_GATEWAY_TOKEN`, `HAOCLAW_GATEWAY_PASSWORD`).
- Gateway auth resolution follows the shared contract used by other Gateway clients:
  - local mode: env (`HAOCLAW_GATEWAY_*`) -> `gateway.auth.*` -> `gateway.remote.*` fallback when `gateway.auth.*` is unset
  - remote mode: `gateway.remote.*` with env/config fallback per remote precedence rules
  - `--url` is override-safe and does not reuse implicit config/env credentials; pass explicit `--token`/`--password` (or file variants)
- ACP runtime backend child processes receive `HAOCLAW_SHELL=acp`, which can be used for context-specific shell/profile rules.
- `haoclaw acp client` sets `HAOCLAW_SHELL=acp-client` on the spawned bridge process.

### `acp client` options

- `--cwd <dir>`: working directory for the ACP session.
- `--server <command>`: ACP server command (default: `haoclaw`).
- `--server-args <args...>`: extra arguments passed to the ACP server.
- `--server-verbose`: enable verbose logging on the ACP server.
- `--verbose, -v`: verbose client logging.
