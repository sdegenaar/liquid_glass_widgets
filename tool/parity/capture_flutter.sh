#!/usr/bin/env bash
# Usage: cap.sh "<harness command>" <output-name> [settle-seconds]
# Sends one command to the Flutter parity harness, waits, screenshots the booted simulator.
set -euo pipefail
OUT="/Users/sdegenaar/development/liquid_glass_widgets/tool/parity/captures"
UDID="03F92F78-8215-4980-9D92-F0F910F78573"
echo "$1" > /tmp/lgw_parity_cmd.txt
sleep "${3:-1.5}"
xcrun simctl io "$UDID" screenshot "$OUT/flutter_$2.png" >/dev/null 2>&1
echo "captured flutter_$2.png"
