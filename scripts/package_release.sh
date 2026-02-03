#!/bin/bash

# Package script for TRAE Manager

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$PROJECT_ROOT/release"
SWIFT_BUILD_DIR="$PROJECT_ROOT/swift/TraeManager/build"

echo "📦 Packaging TRAE Manager..."

# 1. Clean and Create Release Dir
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# 2. Build macOS App
echo "🍎 Building macOS App..."
cd "$PROJECT_ROOT/swift/TraeManager"
./build.sh > /dev/null

# 3. Copy App to Release
echo "📋 Copying artifacts..."
cp -r "$SWIFT_BUILD_DIR/TraeManager.app" "$RELEASE_DIR/"

# 4. Create macOS Zip
cd "$RELEASE_DIR"
zip -r "TraeManager-macOS.zip" "TraeManager.app"
rm -rf "TraeManager.app"

# 5. Copy Scripts (CLI & Windows)
mkdir -p "$RELEASE_DIR/scripts"
cp "$PROJECT_ROOT/scripts/trae-mgr" "$RELEASE_DIR/scripts/"
if [ -f "$PROJECT_ROOT/scripts/windows/trae-mgr.ps1" ]; then
    cp "$PROJECT_ROOT/scripts/windows/trae-mgr.ps1" "$RELEASE_DIR/scripts/"
fi

echo "✅ Release ready at: $RELEASE_DIR"
ls -lh "$RELEASE_DIR"
