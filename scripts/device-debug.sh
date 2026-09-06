#!/usr/bin/env bash
set -euo pipefail

# Headless HarmonyOS device workflow. The default command only checks the
# connection and never launches the app. Set DEVICE_SERIAL for Wi-Fi devices.
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE_SERIAL="${DEVICE_SERIAL:-192.168.0.107:34973}"
MODULE="${MODULE:-entry@default}"
HAP_PATH="$ROOT_DIR/entry/build/default/outputs/default/entry-default-signed.hap"

usage() {
  cat <<'EOF'
Usage: scripts/device-debug.sh [command]

Commands:
  connect       Check the connected device only (default; does not launch app)
  build         Build a debug HAP without installing or launching
  install       Install the existing signed HAP without launching (requires hdc)
  launch        Build/install and launch through DevEco CLI
  logs          Follow this app's error logs
  layout        Dump the current device UI layout
  screenshot    Save a screenshot (SCREENSHOT_PATH can override the path)

Environment:
  DEVICE_SERIAL  Device name or serial, e.g. 192.168.0.107:34973
  HDC_BIN        Optional path to hdc for install-only mode
EOF
}

connect_device() {
  devecocli device view --target "$DEVICE_SERIAL" --format json
}

case "${1:-connect}" in
  connect)
    connect_device
    ;;
  build)
    cd "$ROOT_DIR"
    devecocli build --product default --modules "$MODULE" --build-mode debug
    ;;
  install)
    if [[ ! -f "$HAP_PATH" ]]; then
      echo "HAP not found: $HAP_PATH; run '$0 build' first." >&2
      exit 2
    fi
    HDC_BIN="${HDC_BIN:-$(command -v hdc || true)}"
    if [[ -z "$HDC_BIN" ]]; then
      echo "hdc is not available. Install HarmonyOS command-line tools or set HDC_BIN." >&2
      exit 2
    fi
    "$HDC_BIN" -t "$DEVICE_SERIAL" install -r "$HAP_PATH"
    echo "Installed without launching: $HAP_PATH"
    ;;
  launch)
    cd "$ROOT_DIR"
    devecocli run --module "$MODULE" --device "$DEVICE_SERIAL"
    ;;
  logs)
    devecocli log --device "$DEVICE_SERIAL" --bundle-name io.github.qinlinglong.guozaoke --level E --follow
    ;;
  layout)
    devecocli ui layout --device "$DEVICE_SERIAL" --format json
    ;;
  screenshot)
    SCREENSHOT_PATH="${SCREENSHOT_PATH:-$ROOT_DIR/device-screenshot.png}"
    devecocli ui screenshot --device "$DEVICE_SERIAL" --path "$SCREENSHOT_PATH"
    echo "Screenshot: $SCREENSHOT_PATH"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: $1" >&2
    usage >&2
    exit 2
    ;;
esac
