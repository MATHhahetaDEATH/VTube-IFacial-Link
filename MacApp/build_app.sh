#!/bin/bash
set -e

APP_NAME="VTube-IFacial-Link"
BUNDLE_DIR="build/${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "=== Building VTube-IFacial-Link.app ==="

# 1. Build release binaries
echo "Building release binaries..."
swift build -c release

# 2. Create .app bundle structure
echo "Creating app bundle..."
rm -rf "build"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 3. Copy executables
cp .build/release/VTubeLinkUI "${MACOS_DIR}/VTubeLinkUI"
cp .build/release/VTubeLinkService "${MACOS_DIR}/VTubeLinkService"

# 4. Copy and Compile Assets (Icons)
echo "Compiling assets..."
actool "Resources/Assets.xcassets" --compile "${RESOURCES_DIR}" \
    --platform macosx --minimum-deployment-target 12.0 \
    --app-icon AppIcon --output-partial-info-plist /tmp/partial.plist --output-format xml1

# 5. Use external Info.plist
echo "Applying Info.plist..."
cp "Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"

echo ""
echo "=== Build Complete ==="
echo "App bundle created at: $(pwd)/${BUNDLE_DIR}"
echo ""
echo "To run:  open build/${APP_NAME}.app"
echo "To distribute: zip the .app or create a DMG"
