#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$DIR/build"
APP_DIR="$BUILD_DIR/ParityApp.app"

echo "=== Building iOS 27 Native SwiftUI Parity Reference App ==="

mkdir -p "$BUILD_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path)
echo "Using SDK: $SDK_PATH"

echo "Compiling ParityApp.swift..."
xcrun -sdk iphonesimulator swiftc \
    -parse-as-library \
    -target arm64-apple-ios27.0-simulator \
    -sdk "$SDK_PATH" \
    "$DIR/ParityApp.swift" \
    -o "$APP_DIR/ParityApp"

cp "$DIR/Info.plist" "$APP_DIR/Info.plist"

echo "Finding booted iOS simulator..."
BOOTED_DEVICE=$(xcrun simctl list devices | grep "(Booted)" | head -n 1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/' || true)

if [ -z "$BOOTED_DEVICE" ]; then
    echo "No booted simulator found. Booting default iPhone 18 Pro (iOS 27)..."
    BOOTED_DEVICE="03F92F78-8215-4980-9D92-F0F910F78573"
    xcrun simctl boot "$BOOTED_DEVICE" || true
fi

echo "Installing to simulator ($BOOTED_DEVICE)..."
xcrun simctl install "$BOOTED_DEVICE" "$APP_DIR"

echo "Launching com.liquidglass.parityreference..."
xcrun simctl launch "$BOOTED_DEVICE" com.liquidglass.parityreference

echo "=== Native Parity Reference App launched successfully! ==="
