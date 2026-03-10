---
summary: "CLI reference for `haoclaw config` (get/set/unset/file/validate)"
read_when:
  - You want to read or edit config non-interactively
title: "config"
---

# `haoclaw config`

Config helpers: get/set/unset/validate values by path and print the active
config file. Run without a subcommand to open
the configure wizard (same as `haoclaw configure`).

## Examples

```bash
haoclaw config file
haoclaw config get browser.executablePath
haoclaw config set browser.executablePath "/usr/bin/google-chrome"
haoclaw config set agents.defaults.heartbeat.every "2h"
haoclaw config set agents.list[0].tools.exec.node "node-id-or-name"
haoclaw config unset tools.web.search.apiKey
haoclaw config validate
haoclaw config validate --json
```

## Paths

Paths use dot or bracket notation:

```bash
haoclaw config get agents.defaults.workspace
haoclaw config get agents.list[0].id
```

Use the agent list index to target a specific agent:

```bash
haoclaw config get agents.list
haoclaw config set agents.list[1].tools.exec.node "node-id-or-name"
```

## Values

Values are parsed as JSON5 when possible; otherwise they are treated as strings.
Use `--strict-json` to require JSON5 parsing. `--json` remains supported as a legacy alias.

```bash
haoclaw config set agents.defaults.heartbeat.every "0m"
haoclaw config set gateway.port 19001 --strict-json
haoclaw config set channels.whatsapp.groups '["*"]' --strict-json
```

## Subcommands

- `config file`: Print the active config file path (resolved from `HAOCLAW_CONFIG_PATH` or default location).

Restart the gateway after edits.

## Validate

Validate the current config against the active schema without starting the
gateway.

```bash
haoclaw config validate
haoclaw config validate --json
```
