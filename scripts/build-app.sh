#!/bin/bash

# Build DeVoice.app for macOS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="DeVoice"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "🔨 Building DeVoice..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build release binary
cd "$PROJECT_DIR/DeVoice"
swift build -c release

# Create app bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp .build/release/DeVoice "$APP_BUNDLE/Contents/MacOS/"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>DeVoice</string>
    <key>CFBundleDisplayName</key>
    <string>DeVoice</string>
    <key>CFBundleIdentifier</key>
    <string>com.devoice.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>DeVoice</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>DeVoice needs microphone access to record your voice and convert it to text.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Sign the app
echo "🔏 Signing app..."

# Try to use DeVoice Development certificate first, fall back to ad-hoc
CERT_NAME="DeVoice Development"
if security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
    echo "   Using '$CERT_NAME' certificate"
    codesign --force --deep --sign "$CERT_NAME" "$APP_BUNDLE"
else
    echo "   Using ad-hoc signature (run scripts/create-certificate.sh for persistent signing)"
    codesign --force --deep --sign - "$APP_BUNDLE"
fi

echo ""
echo "✅ Build complete: $APP_BUNDLE"
echo ""
echo "To install, run:"
echo "  cp -r \"$APP_BUNDLE\" /Applications/"
echo ""
echo "Or drag DeVoice.app from build/ to your Applications folder."
