#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v node >/dev/null 2>&1; then
  echo "haoclaw deploy: Node.js is required." >&2
  exit 1
fi

if ! command -v pnpm >/dev/null 2>&1; then
  if command -v corepack >/dev/null 2>&1; then
    corepack enable >/dev/null 2>&1 || true
  fi
fi

if ! command -v pnpm >/dev/null 2>&1; then
  echo "haoclaw deploy: pnpm is required." >&2
  exit 1
fi

if [ ! -d node_modules ]; then
  echo "[haoclaw] Installing dependencies..."
  pnpm install
fi

echo "[haoclaw] Running one-click deployment..."
node scripts/run-node.mjs deploy "$@"
