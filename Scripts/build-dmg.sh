#!/bin/bash
# Builds a standalone RC505Player.app and packages it into a DMG for sharing
# with other Macs. Run from Terminal: ./Scripts/build-dmg.sh
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="RC505Player"
DISPLAY_NAME="RC-505 Player"
BUNDLE_ID="com.adriansinnott.RC505Player"
VERSION="1.0"
OUT_DIR="build"
APP_BUNDLE="${OUT_DIR}/${APP_NAME}.app"
DMG_PATH="${OUT_DIR}/${APP_NAME}.dmg"

echo "==> Cleaning previous build"
rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

echo "==> Building universal (Apple Silicon + Intel) release binary"
if swift build -c release --arch arm64 --arch x86_64; then
    BIN_DIR=".build/apple/Products/Release"
else
    echo "==> Universal build failed, falling back to a build for this Mac only"
    swift build -c release
    BIN_DIR=".build/release"
fi

echo "==> Assembling app bundle"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
cp "${BIN_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

cat > "${APP_BUNDLE}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${DISPLAY_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${DISPLAY_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.music</string>
</dict>
</plist>
PLIST

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Creating DMG"
hdiutil create -volname "${DISPLAY_NAME}" -srcfolder "${APP_BUNDLE}" -ov -format UDZO "${DMG_PATH}"

echo "==> Done: ${DMG_PATH}"
