---
summary: "CLI reference for `haoclaw uninstall` (remove gateway service + local data)"
read_when:
  - You want to remove the gateway service and/or local state
  - You want a dry-run first
title: "uninstall"
---

# `haoclaw uninstall`

Uninstall the gateway service + local data (CLI remains).

```bash
haoclaw backup create
haoclaw uninstall
haoclaw uninstall --all --yes
haoclaw uninstall --dry-run
```

Run `haoclaw backup create` first if you want a restorable snapshot before removing state or workspaces.
