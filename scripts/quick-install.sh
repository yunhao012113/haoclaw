#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${HAOCLAW_REPO_URL:-https://github.com/yunhao012113/haoclaw.git}"
INSTALL_DIR="${HAOCLAW_INSTALL_DIR:-$HOME/.haoclaw/app}"
BIN_DIR="${HAOCLAW_BIN_DIR:-$HOME/.local/bin}"
GATEWAY_PORT="18789"

parse_gateway_port() {
  local previous=""
  for arg in "$@"; do
    if [ "$previous" = "--gateway-port" ]; then
      GATEWAY_PORT="$arg"
      previous=""
      continue
    fi
    case "$arg" in
      --gateway-port=*)
        GATEWAY_PORT="${arg#--gateway-port=}"
        ;;
      --gateway-port)
        previous="--gateway-port"
        ;;
      *)
        previous=""
        ;;
    esac
  done
}

install_global_launcher() {
  mkdir -p "$BIN_DIR"
  cat >"$BIN_DIR/haoclaw" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "$INSTALL_DIR"
exec node scripts/run-node.mjs "\$@"
EOF
  chmod +x "$BIN_DIR/haoclaw"
}

print_finish_message() {
  echo
  echo "[haoclaw] Install complete"
  echo "[haoclaw] App directory: $INSTALL_DIR"
  echo "[haoclaw] Global command: $BIN_DIR/haoclaw"
  echo "[haoclaw] Gateway URL: http://127.0.0.1:${GATEWAY_PORT}"
  echo "[haoclaw] Health check: http://127.0.0.1:${GATEWAY_PORT}/health"
  case ":${PATH:-}:" in
    *":$BIN_DIR:"*) ;;
    *)
      echo
      echo "[haoclaw] Add this to your shell profile if 'haoclaw' is not found:"
      echo "export PATH=\"$BIN_DIR:\$PATH\""
      ;;
  esac
  echo
  echo "[haoclaw] Quick commands:"
  echo "  haoclaw health"
  echo "  haoclaw agent --agent main --message \"你好\""
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "haoclaw quick-install: missing required command: $1" >&2
    exit 1
  fi
}

ensure_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then
    return
  fi
  if command -v corepack >/dev/null 2>&1; then
    corepack enable >/dev/null 2>&1 || true
  fi
  if ! command -v pnpm >/dev/null 2>&1; then
    echo "haoclaw quick-install: pnpm is required. Install Node.js with corepack support or install pnpm manually." >&2
    exit 1
  fi
}

need_cmd git
need_cmd node
ensure_pnpm
parse_gateway_port "$@"

mkdir -p "$(dirname "$INSTALL_DIR")"

if [ -d "$INSTALL_DIR/.git" ]; then
  echo "[haoclaw] Updating existing checkout in $INSTALL_DIR"
  git -C "$INSTALL_DIR" fetch origin main --depth=1
  git -C "$INSTALL_DIR" reset --hard origin/main
else
  echo "[haoclaw] Cloning repository to $INSTALL_DIR"
  rm -rf "$INSTALL_DIR"
  git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

if [ ! -d node_modules ]; then
  echo "[haoclaw] Installing dependencies"
  pnpm install
fi

echo "[haoclaw] Running one-click deployment"
node scripts/run-node.mjs deploy "$@"
install_global_launcher
print_finish_message
