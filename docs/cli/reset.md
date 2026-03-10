---
summary: "CLI reference for `haoclaw reset` (reset local state/config)"
read_when:
  - You want to wipe local state while keeping the CLI installed
  - You want a dry-run of what would be removed
title: "reset"
---

# `haoclaw reset`

Reset local config/state (keeps the CLI installed).

```bash
haoclaw backup create
haoclaw reset
haoclaw reset --dry-run
haoclaw reset --scope config+creds+sessions --yes --non-interactive
```

Run `haoclaw backup create` first if you want a restorable snapshot before removing local state.
