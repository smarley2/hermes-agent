#!/usr/bin/env bash
# Launch CloakBrowser stealth Chromium with a CDP endpoint for Hermes.
#
# CloakBrowser ships its `cloakserve` CDP multiplexer only in the Docker
# image. With the pip install we drive the binary directly with
# --remote-debugging-port, which exposes the same CDP endpoint Hermes'
# browser tools attach to via `browser.cdp_url`.
#
# Usage:
#   cloakserve-hermes [--headless=new|false] [--proxy-server=...] [extra chromium flags...]
#
# Defaults:
#   - listens on 127.0.0.1:9222
#   - persistent profile at ~/.cloakbrowser/profile
#   - headless=new (override with --headless=false or --headed)
#
# Environment overrides:
#   CLOAKBROWSER_BINARY_PATH explicit Chromium/CloakBrowser executable path
#   CLOAK_PYTHON      Python interpreter used to query cloakbrowser (default: python3)
#   CLOAK_BIN_DIR     base dir holding chromium-* releases (default: ~/.cloakbrowser)
#   CLOAK_PROFILE_DIR profile dir (default: $CLOAK_BIN_DIR/profile)
#   CLOAK_PORT        CDP port (default: 9222)
#   CLOAK_ADDR        CDP bind address (default: 127.0.0.1)

set -euo pipefail

BIN_DIR="${CLOAK_BIN_DIR:-$HOME/.cloakbrowser}"
PROFILE_DIR="${CLOAK_PROFILE_DIR:-$BIN_DIR/profile}"
PORT="${CLOAK_PORT:-9222}"
ADDR="${CLOAK_ADDR:-127.0.0.1}"
PYTHON_BIN="${CLOAK_PYTHON:-python3}"

resolve_chrome_bin() {
  if [[ -n "${CLOAKBROWSER_BINARY_PATH:-}" && -x "${CLOAKBROWSER_BINARY_PATH}" ]]; then
    printf '%s\n' "${CLOAKBROWSER_BINARY_PATH}"
    return 0
  fi

  # Preferred path: ask the installed cloakbrowser package. This handles
  # Linux (chrome), Windows (chrome.exe), and macOS app bundles
  # (Chromium.app/Contents/MacOS/Chromium), and also triggers the package's
  # normal binary-location fallback logic.
  if command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    local from_python
    from_python=$("$PYTHON_BIN" - <<'PY' 2>/dev/null || true
try:
    from cloakbrowser.download import ensure_binary
    print(ensure_binary())
except Exception:
    pass
PY
)
    if [[ -n "$from_python" && -x "$from_python" ]]; then
      printf '%s\n' "$from_python"
      return 0
    fi
  fi

  # Fallback for older/manual installs. Keep macOS bundle support explicit;
  # the original PR only looked for chromium-*/chrome, which misses darwin.
  local candidate
  for candidate in \
    "$BIN_DIR"/chromium-*/chrome \
    "$BIN_DIR"/chromium-*/chrome.exe \
    "$BIN_DIR"/chromium-*/Chromium.app/Contents/MacOS/Chromium; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

CHROME_BIN=$(resolve_chrome_bin || true)
if [[ -z "$CHROME_BIN" ]]; then
  echo "cloakserve-hermes: CloakBrowser binary not found under $BIN_DIR." >&2
  echo "cloakserve-hermes: install with: python -m pip install cloakbrowser && python -m cloakbrowser install" >&2
  echo "cloakserve-hermes: or set CLOAKBROWSER_BINARY_PATH to a local Chromium binary." >&2
  exit 1
fi

mkdir -p "$PROFILE_DIR"

# Clear stale singleton lock files from a previous crashed run. Chromium
# leaves these behind when killed forcefully and refuses to start with
# exit code 21 until they are gone.
rm -f "$PROFILE_DIR/SingletonLock" \
      "$PROFILE_DIR/SingletonCookie" \
      "$PROFILE_DIR/SingletonSocket"

HEADLESS_DEFAULT="--headless=new"
for arg in "$@"; do
  case "$arg" in
    --headless=*|--headed) HEADLESS_DEFAULT="" ;;
  esac
done

exec "$CHROME_BIN" \
  --remote-debugging-port="$PORT" \
  --remote-debugging-address="$ADDR" \
  --user-data-dir="$PROFILE_DIR" \
  --no-first-run \
  --no-default-browser-check \
  --disable-dev-shm-usage \
  $HEADLESS_DEFAULT \
  "$@"
