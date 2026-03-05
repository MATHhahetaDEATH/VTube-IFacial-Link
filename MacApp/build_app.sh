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

# 4. Create Info.plist
cat > "${CONTENTS_DIR}/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>VTube-IFacial-Link</string>
    <key>CFBundleDisplayName</key>
    <string>VTube IFacial Link</string>
    <key>CFBundleIdentifier</key>
    <string>com.vtubelink.ifacialmocap</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>VTubeLinkUI</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
PLIST

# 5. Create a simple launcher script that wraps VTubeLinkUI (optional, if needed)
# The main executable is already VTubeLinkUI, which can find VTubeLinkService next to it.

echo ""
echo "=== Build Complete ==="
echo "App bundle created at: $(pwd)/${BUNDLE_DIR}"
echo ""
echo "To run:  open build/${APP_NAME}.app"
echo "To distribute: zip the .app or create a DMG"
