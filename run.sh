#!/usr/bin/env bash
# Understand-Anything — one-command runner for the interactive dashboard (macOS/Linux).
# Works from a fresh clone, NO sudo required.
#
#     ./run.sh            # build (if needed) + serve the DEMO dashboard (populated graph, no token)
#     ./run.sh --live     # serve a LIVE project's graph instead (needs /understand output; token-gated)
#     ./run.sh --reset    # force a clean reinstall + rebuild first
#
# Demo mode (default) shows a fully populated graph immediately — open the printed URL.
# Press Ctrl+C to stop.
set -euo pipefail
export MSYS_NO_PATHCONV=1   # harmless on real unix; stops Git-Bash mangling "--base=/"
cd "$(dirname "$0")"
PNPM_VER=10.6.2
DASH="understand-anything-plugin/packages/dashboard"
have() { command -v "$1" >/dev/null 2>&1; }

have node || { echo "Node.js 18+ is required. Install from https://nodejs.org and re-run."; exit 1; }

if ! have pnpm; then
  echo "-> pnpm not found; provisioning..."
  { corepack enable && corepack prepare "pnpm@$PNPM_VER" --activate; } 2>/dev/null || true
  have pnpm || npm install -g "pnpm@$PNPM_VER"
fi
have pnpm || { echo "Could not provision pnpm. Run: npm install -g pnpm@$PNPM_VER"; exit 1; }
echo "OK pnpm $(pnpm -v)"

MODE="${1:-}"
if [ "$MODE" = "--reset" ]; then echo "-> Reset..."; rm -rf node_modules "$DASH/dist"; MODE=""; fi

[ -d node_modules ] || { echo "-> Installing dependencies (first run)..."; pnpm install; }
[ -d understand-anything-plugin/packages/core/dist ] || { echo "-> Building core (first run)..."; pnpm --filter "@understand-anything/core" build; }

if [ "$MODE" = "--live" ]; then
  echo; echo "-> LIVE mode. Open the printed URL (with ?token=). Ctrl+C to stop."; echo
  exec pnpm -C "$DASH" dev
fi

# DEMO mode (default)
if [ ! -f "$DASH/dist/.uademo" ]; then
  echo "-> Building demo dashboard (first run)..."
  pnpm -C "$DASH" exec vite build --config vite.config.demo.ts --base=/
  : > "$DASH/dist/.uademo"
fi
echo
echo "==================================================================="
echo "  Dashboard (demo): open the 'Local:' URL printed below"
echo "  (usually http://127.0.0.1:5173/). Ctrl+C to stop."
echo "  Demo graph. To graph YOUR code, see HOW_TO_RUN.md (Claude Code plugin)."
echo "==================================================================="
echo
exec pnpm -C "$DASH" exec vite preview --base=/ --port 5173
