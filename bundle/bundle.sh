#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building Ping (release)..."
swift build -c release

BUILD_DIR="../.build/arm64-apple-macosx/release"
BINARY="$BUILD_DIR/Ping"
RESOURCE_BUNDLE="$BUILD_DIR/Ping_Ping.bundle"
APP="Ping.app"

if [ ! -f "$BINARY" ]; then
    echo "Error: Binary not found at $BINARY"
    exit 1
fi

# Remove any existing .app bundle
rm -rf "$APP"

# Create directory structure
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

# Copy binary
cp "$BINARY" "$APP/Contents/MacOS/Ping"

# Copy Info.plist
cp Info.plist "$APP/Contents/Info.plist"

# Copy app icon
cp Ping.icns "$APP/Contents/Resources/Ping.icns"

# Write PkgInfo
echo -n "APPL????" > "$APP/Contents/PkgInfo"

# Copy resource bundle to root of .app (where Bundle.module expects it)
if [ -d "$RESOURCE_BUNDLE" ]; then
    cp -R "$RESOURCE_BUNDLE" "$APP/Ping_Ping.bundle"
else
    echo "Warning: Resource bundle not found at $RESOURCE_BUNDLE, skipping"
fi

# Ad-hoc codesign for local use (may warn about unsealed contents)
if codesign --force --deep --sign - "$APP" 2>/dev/null; then
    echo "Codesigned $APP"
else
    echo "Note: Codesigning skipped (unsealed bundle root). App will still run locally."
fi

echo "Built $APP successfully"
echo "Run with: open $APP"
