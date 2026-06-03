# This is for local versions of the repoistary (git clone), adapated from the github CI and designe dto aubil dconflicting with the files or the original repositary.
# This is because I build with GitHub CI, but do local testing with Xcode, and syncing the two, while not divering too much from the original repoistary is painful.

#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Internetperson-dev/liquid_glass_widgets/new/main/.github/workflows"
WORKSPACE="$HOME/projects/liquid_glass_widgets"

FLUTTER_VERSION="3.41.9"

APPS=(
  apple_music
  apple_podcasts
  apple_messages
  apple_news
  showcase
)

###############################################################################
# Clone
###############################################################################

rm -rf "$WORKSPACE"

git clone "$REPO_URL" "$WORKSPACE"
cd "$WORKSPACE"

###############################################################################
# Patch GlassQuality
###############################################################################

find . -type f -name "*.dart" | while read -r file; do
  sed -i.bak \
    's/GlassQuality\.premium/GlassQuality.standard/g' \
    "$file" || true

  rm -f "${file}.bak"
done

###############################################################################
# Flutter
###############################################################################

flutter --version

flutter config \
  --enable-web \
  --enable-linux-desktop \
  --enable-macos-desktop \
  --enable-windows-desktop

###############################################################################
# Platform scaffolding
###############################################################################

cd example

flutter create . \
  --platforms=android,ios,web,linux,macos,windows

cd showcase

flutter create . \
  --platforms=android,ios,web,linux,macos,windows

cd ..

###############################################################################
# Dependencies
###############################################################################

flutter pub get

cd example
flutter pub get

cd showcase
flutter pub get

cd "$WORKSPACE"

###############################################################################
# Artifacts
###############################################################################

mkdir -p artifacts

mkdir -p artifacts/android
mkdir -p artifacts/ios
mkdir -p artifacts/web
mkdir -p artifacts/linux
mkdir -p artifacts/windows
mkdir -p artifacts/macos

###############################################################################
# Build Loop
###############################################################################

for APP in "${APPS[@]}"; do

  echo ""
  echo "===================================="
  echo "BUILDING $APP"
  echo "===================================="

  if [ "$APP" = "showcase" ]; then
    ROOT="example/showcase"
    ENTRY="lib/main.dart"
  else
    ROOT="example"
    ENTRY="lib/${APP}/${APP}_demo.dart"
  fi

  cd "$WORKSPACE/$ROOT"

  flutter clean
  flutter pub get

  ###########################################################################
  # iOS (Local Build)
  ###########################################################################

  flutter build ios \
    --release \
    --no-codesign \
    -t "$ENTRY"

  APP_PATH="build/ios/iphoneos/Runner.app"

  if [ -d "$APP_PATH" ]; then
      echo "iOS build generated for $APP"
      echo "Xcode project: $WORKSPACE/$ROOT/ios/Runner.xcworkspace"
      echo "Complete signing and building in Xcode GUI"
  fi

done

###############################################################################
# Final Archives
###############################################################################

cd "$WORKSPACE"

tar -czf ios-builds.tar.gz artifacts/ios 2>/dev/null || echo "iOS artifacts not available"
tar -czf macos-builds.tar.gz artifacts/macos 2>/dev/null || echo "macOS artifacts not available"

echo ""
echo "Build complete."
echo ""
echo "Artifacts:"
find artifacts

echo ""
echo "Next - Continue Development in the GUI of Xcode for building, deployment, and profiling,"
