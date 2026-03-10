---
summary: "CLI reference for `haoclaw devices` (device pairing + token rotation/revocation)"
read_when:
  - You are approving device pairing requests
  - You need to rotate or revoke device tokens
title: "devices"
---

# `haoclaw devices`

Manage device pairing requests and device-scoped tokens.

## Commands

### `haoclaw devices list`

List pending pairing requests and paired devices.

```
haoclaw devices list
haoclaw devices list --json
```

### `haoclaw devices remove <deviceId>`

Remove one paired device entry.

```
haoclaw devices remove <deviceId>
haoclaw devices remove <deviceId> --json
```

### `haoclaw devices clear --yes [--pending]`

Clear paired devices in bulk.

```
haoclaw devices clear --yes
haoclaw devices clear --yes --pending
haoclaw devices clear --yes --pending --json
```

### `haoclaw devices approve [requestId] [--latest]`

Approve a pending device pairing request. If `requestId` is omitted, Haoclaw
automatically approves the most recent pending request.

```
haoclaw devices approve
haoclaw devices approve <requestId>
haoclaw devices approve --latest
```

### `haoclaw devices reject <requestId>`

Reject a pending device pairing request.

```
haoclaw devices reject <requestId>
```

### `haoclaw devices rotate --device <id> --role <role> [--scope <scope...>]`

Rotate a device token for a specific role (optionally updating scopes).

```
haoclaw devices rotate --device <deviceId> --role operator --scope operator.read --scope operator.write
```

### `haoclaw devices revoke --device <id> --role <role>`

Revoke a device token for a specific role.

```
haoclaw devices revoke --device <deviceId> --role node
```

## Common options

- `--url <url>`: Gateway WebSocket URL (defaults to `gateway.remote.url` when configured).
- `--token <token>`: Gateway token (if required).
- `--password <password>`: Gateway password (password auth).
- `--timeout <ms>`: RPC timeout.
- `--json`: JSON output (recommended for scripting).

Note: when you set `--url`, the CLI does not fall back to config or environment credentials.
Pass `--token` or `--password` explicitly. Missing explicit credentials is an error.

## Notes

- Token rotation returns a new token (sensitive). Treat it like a secret.
- These commands require `operator.pairing` (or `operator.admin`) scope.
- `devices clear` is intentionally gated by `--yes`.
- If pairing scope is unavailable on local loopback (and no explicit `--url` is passed), list/approve can use a local pairing fallback.
