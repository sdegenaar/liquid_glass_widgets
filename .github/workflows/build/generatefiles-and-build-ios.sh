#!/usr/bin/env bash
set -euo pipefail

# Local build script — adapted from CI workflow (mobile.yml)
# Does NOT clone or destroy your local repo.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "Workspace: $WORKSPACE"

###############################################################################
# Check we're in the right repo
###############################################################################
if [ ! -f "$WORKSPACE/pubspec.yaml" ]; then
  echo "ERROR: Could not find pubspec.yaml at $WORKSPACE"
  echo "Are you in the liquid_glass_widgets repo?"
  exit 1
fi

###############################################################################
# Patch GlassQuality (optional — uncomment to enable)
###############################################################################
# find "$WORKSPACE" -type f -name "*.dart" | while read -r file; do
#   sed -i.bak \
#     's/GlassQuality\.premium/GlassQuality.standard/g' \
#     "$file" || true
#   rm -f "${file}.bak"
# done

###############################################################################
# Flutter version check
###############################################################################
flutter --version

###############################################################################
# Apps to build
###############################################################################
APPS=(
  apple_music
  apple_podcasts
  apple_messages
  apple_news
  showcase
)

###############################################################################
# Ensure platform scaffolding exists
###############################################################################
ensure_platforms() {
  local dir="$1"
  shift
  local platforms="$*"

  if [ ! -f "$dir/pubspec.yaml" ]; then
    echo "Missing pubspec.yaml in $dir — skipping"
    return
  fi

  cd "$dir"

  local missing=()
  for p in $platforms; do
    case "$p" in
      ios)     [ ! -d ios ]     && missing+=("ios")     ;;
      android) [ ! -d android ] && missing+=("android") ;;
      web)     [ ! -d web ]     && missing+=("web")     ;;
      macos)   [ ! -d macos ]   && missing+=("macos")   ;;
      linux)   [ ! -d linux ]   && missing+=("linux")   ;;
      windows) [ ! -d windows ] && missing+=("windows") ;;
    esac
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "Regenerating missing platforms: ${missing[*]}"
    flutter create . --platforms="$(IFS=,; echo "${missing[*]}")"
  fi
}

###############################################################################
# Dependencies
###############################################################################
cd "$WORKSPACE"
flutter pub get

ensure_platforms "$WORKSPACE/example" ios android
cd "$WORKSPACE/example"
flutter pub get

ensure_platforms "$WORKSPACE/example/showcase" ios android
cd "$WORKSPACE/example/showcase"
flutter pub get

###############################################################################
# Artifacts
###############################################################################
mkdir -p "$WORKSPACE/artifacts/ios"

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

    # Package as IPA (unsigned)
    rm -rf Payload
    mkdir Payload
    cp -R "$APP_PATH" Payload/
    zip -qry "${APP}.ipa" Payload
    mv "${APP}.ipa" "$WORKSPACE/artifacts/ios/"
    echo "Unsigned IPA saved to artifacts/ios/${APP}.ipa"
  fi

done

###############################################################################
# Summary
###############################################################################
echo ""
echo "Build complete."
echo ""
echo "Artifacts:"
find "$WORKSPACE/artifacts" -type f
