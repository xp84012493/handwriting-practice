#!/usr/bin/env bash
# Save a screenshot from the booted iOS Simulator (iPhone-only app).
#
# Prerequisite: Simulator is booted with the app showing the screen you want.
#   open -a Simulator
#   flutter run -d "iPhone 16 Pro Max"
#
# Usage:
#   ./tool/capture_ios_screenshots.sh iphone [output.png]
#   ./tool/capture_ios_screenshots.sh booted [output.png]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-booted}"
OUT="${2:-}"

mkdir -p "$ROOT/store-screenshots/iphone"

boot_simulator() {
  local name="$1"
  local udid
  udid="$(xcrun simctl list devices available | grep "$name" | grep -v unavailable | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')"
  if [[ -z "$udid" ]]; then
    echo "No simulator matching: $name" >&2
    echo "Run: xcrun simctl list devices available" >&2
    exit 1
  fi
  echo "Booting: $name ($udid)"
  xcrun simctl boot "$udid" 2>/dev/null || true
  open -a Simulator
  xcrun simctl bootstatus "$udid" -b
}

case "$MODE" in
  iphone)
    boot_simulator "iPhone 16 Pro Max"
    OUT="${OUT:-$ROOT/store-screenshots/iphone/$(date +%Y%m%d-%H%M%S)-practice.png}"
    ;;
  booted)
    OUT="${OUT:-$ROOT/store-screenshots/iphone/$(date +%Y%m%d-%H%M%S)-screenshot.png}"
    ;;
  *)
    echo "Usage: $0 {iphone|booted} [output.png]" >&2
    exit 1
    ;;
esac

xcrun simctl io booted screenshot "$OUT"
echo "Saved: $OUT"

if command -v sips >/dev/null 2>&1; then
  sips -g pixelWidth -g pixelHeight "$OUT" 2>/dev/null | grep pixel || true
fi

echo ""
echo "App Store (iPhone-only): portrait 1290x2796 (6.9\" display, or 1320x2868 / 1260x2736)"
echo "See docs/STORE_LAUNCH_CHECKLIST.md"
