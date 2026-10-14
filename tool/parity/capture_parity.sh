#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAPTURES_DIR="$DIR/captures"
mkdir -p "$CAPTURES_DIR"

echo "=== Running iOS 27 Native Parity Capture Harness ==="

# 1. Build and install native reference app
"$DIR/ios_reference/build_and_run.sh"

BOOTED_DEVICE=$(xcrun simctl list devices | grep "(Booted)" | head -n 1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/' || true)

if [ -z "$BOOTED_DEVICE" ]; then
    echo "Error: No booted simulator found."
    exit 1
fi

echo "Using Simulator Device: $BOOTED_DEVICE"

capture_tab() {
    local tab="$1"
    local name="$2"
    local extra="${3:-}"
    
    echo "Capturing Tab $tab -> $name..."
    xcrun simctl terminate "$BOOTED_DEVICE" com.liquidglass.parityreference 2>/dev/null || true
    if [ -n "$extra" ]; then
        xcrun simctl launch "$BOOTED_DEVICE" com.liquidglass.parityreference -tab "$tab" "$extra" >/dev/null
    else
        xcrun simctl launch "$BOOTED_DEVICE" com.liquidglass.parityreference -tab "$tab" >/dev/null
    fi
    sleep 1.2
    xcrun simctl io "$BOOTED_DEVICE" screenshot "$CAPTURES_DIR/$name"
}

capture_tab 0 "native_tab0_swipe_and_menu.png"
capture_tab 1 "native_tab1_disclosure.png"
capture_tab 2 "native_tab2_edit_mode.png"
capture_tab 3 "native_tab3_pickers.png"
capture_tab 4 "native_tab4_modals_nav.png"
capture_tab 4 "native_tab4_fullscreen_cover_presented.png" "-presentCover"

echo ""
echo "=== Parity Screenshots Captured Successfully in $CAPTURES_DIR ==="
ls -lh "$CAPTURES_DIR"
