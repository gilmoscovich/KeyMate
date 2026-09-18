#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${SHORTCUT_BUILD_DIR:-$PROJECT_DIR/.build-local}"
export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$BUILD_DIR/module-cache"
for ARCH in arm64 x86_64; do
    swift build --package-path "$PROJECT_DIR" --scratch-path "$BUILD_DIR/$ARCH" --cache-path "$BUILD_DIR/cache" --disable-sandbox -c release --triple "$ARCH-apple-macosx14.0"
done
ARM_BIN_DIR="$(swift build --package-path "$PROJECT_DIR" --scratch-path "$BUILD_DIR/arm64" --cache-path "$BUILD_DIR/cache" --disable-sandbox -c release --triple arm64-apple-macosx14.0 --show-bin-path)"
INTEL_BIN_DIR="$(swift build --package-path "$PROJECT_DIR" --scratch-path "$BUILD_DIR/x86_64" --cache-path "$BUILD_DIR/cache" --disable-sandbox -c release --triple x86_64-apple-macosx14.0 --show-bin-path)"
APP_DIR="$PROJECT_DIR/../KeyMate.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
ASSET_OUTPUT_DIR="$BUILD_DIR/AppIconAssets"
rm -rf "$ASSET_OUTPUT_DIR"
mkdir -p "$ASSET_OUTPUT_DIR"
xcrun actool "$PROJECT_DIR/Resources/Assets.xcassets" --compile "$ASSET_OUTPUT_DIR" --platform macosx --minimum-deployment-target 14.0 --app-icon AppIcon --output-partial-info-plist "$ASSET_OUTPUT_DIR/Info.plist" >/dev/null
cp "$ASSET_OUTPUT_DIR/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$ASSET_OUTPUT_DIR/Assets.car" "$APP_DIR/Contents/Resources/Assets.car"
cp "$PROJECT_DIR/Resources/AppIcons/AppIcon-Light.png" "$APP_DIR/Contents/Resources/AppIcon-Light.png"
cp "$PROJECT_DIR/Resources/AppIcons/AppIcon-Dark.png" "$APP_DIR/Contents/Resources/AppIcon-Dark.png"
rm -f "$APP_DIR/Contents/MacOS/ShortcutFinder"
lipo -create "$ARM_BIN_DIR/ShortcutFinder" "$INTEL_BIN_DIR/ShortcutFinder" -output "$APP_DIR/Contents/MacOS/ShortcutFinder"
rm -rf "$APP_DIR/Contents/Resources/ShortcutFinder_ShortcutCore.bundle"
for bundle in "$ARM_BIN_DIR"/*.bundle; do
    cp -R "$bundle" "$APP_DIR/Contents/Resources/"
done
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.local.ShortcutFinder</string>
<key>CFBundleName</key><string>KeyMate</string>
<key>CFBundleDisplayName</key><string>KeyMate</string>
<key>CFBundleExecutable</key><string>ShortcutFinder</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleIconName</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0.3</string>
<key>CFBundleVersion</key><string>4</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP_DIR"
"$APP_DIR/Contents/MacOS/ShortcutFinder" --verify-installation
printf 'Built: %s\n' "$APP_DIR"
