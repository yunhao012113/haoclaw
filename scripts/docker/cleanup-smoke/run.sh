#!/usr/bin/env bash
set -euo pipefail

cd /repo

export HAOCLAW_STATE_DIR="/tmp/haoclaw-test"
export HAOCLAW_CONFIG_PATH="${HAOCLAW_STATE_DIR}/haoclaw.json"

echo "==> Build"
pnpm build

echo "==> Seed state"
mkdir -p "${HAOCLAW_STATE_DIR}/credentials"
mkdir -p "${HAOCLAW_STATE_DIR}/agents/main/sessions"
echo '{}' >"${HAOCLAW_CONFIG_PATH}"
echo 'creds' >"${HAOCLAW_STATE_DIR}/credentials/marker.txt"
echo 'session' >"${HAOCLAW_STATE_DIR}/agents/main/sessions/sessions.json"

echo "==> Reset (config+creds+sessions)"
pnpm haoclaw reset --scope config+creds+sessions --yes --non-interactive

test ! -f "${HAOCLAW_CONFIG_PATH}"
test ! -d "${HAOCLAW_STATE_DIR}/credentials"
test ! -d "${HAOCLAW_STATE_DIR}/agents/main/sessions"

echo "==> Recreate minimal config"
mkdir -p "${HAOCLAW_STATE_DIR}/credentials"
echo '{}' >"${HAOCLAW_CONFIG_PATH}"

echo "==> Uninstall (state only)"
pnpm haoclaw uninstall --state --yes --non-interactive

test ! -d "${HAOCLAW_STATE_DIR}"

echo "OK"
