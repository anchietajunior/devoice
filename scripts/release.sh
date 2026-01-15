#!/bin/bash

# Create a release package for DeVoice

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
VERSION="${1:-1.0.0}"

echo "📦 Creating DeVoice v$VERSION release..."

# Build the app first
"$SCRIPT_DIR/build-app.sh"

# Create release directory
RELEASE_DIR="$BUILD_DIR/release"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Copy app to release directory
cp -r "$BUILD_DIR/DeVoice.app" "$RELEASE_DIR/"

# Create zip for GitHub release
cd "$RELEASE_DIR"
zip -r "DeVoice-$VERSION-macOS.zip" "DeVoice.app"
mv "DeVoice-$VERSION-macOS.zip" "$BUILD_DIR/"

# Clean up
rm -rf "$RELEASE_DIR"

echo ""
echo "✅ Release package created:"
echo "   $BUILD_DIR/DeVoice-$VERSION-macOS.zip"
echo ""
echo "To create a GitHub release:"
echo "   1. Go to your repo → Releases → New Release"
echo "   2. Create tag 'v$VERSION'"
echo "   3. Upload: DeVoice-$VERSION-macOS.zip"
echo ""
echo "Users will:"
echo "   1. Download and unzip"
echo "   2. Drag DeVoice.app to Applications"
echo "   3. Right-click → Open (first time only, to bypass Gatekeeper)"
echo "   4. Grant Accessibility permission once"
