#!/bin/bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Yoda"
BUNDLE_ID="com.local.yoda"
BUILD_DIR="$DIR/build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_PATH/Contents"

echo "→ Cleaning..."
rm -rf "$BUILD_DIR"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

# ── Embed HTML as a Swift raw string constant ──────────────────────────────
echo "→ Embedding HTML..."
python3 - "$DIR/yoda.html" "$BUILD_DIR/html_resource.swift" << 'PYEOF'
import sys
with open(sys.argv[1], 'r', encoding='utf-8', errors='replace') as f:
    html = f.read()
html = html.replace('#"""', '#\\"\\"\\"')
swift = 'let yodaHTML: String = #"""\n' + html + '\n"""#\n'
with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(swift)
print(f"  Embedded {len(html)} chars")
PYEOF

# ── Generate icon ──────────────────────────────────────────────────────────
echo "→ Generating icon..."
ICONSET="$BUILD_DIR/yoda.iconset"
mkdir -p "$ICONSET"
python3 "$DIR/make_icon.py" "$BUILD_DIR/icon_1024.png"
for SIZE in 16 32 64 128 256 512; do
    sips -z $SIZE $SIZE "$BUILD_DIR/icon_1024.png" --out "$ICONSET/icon_${SIZE}x${SIZE}.png" > /dev/null 2>&1
    DOUBLE=$((SIZE * 2))
    sips -z $DOUBLE $DOUBLE "$BUILD_DIR/icon_1024.png" --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" > /dev/null 2>&1
done
iconutil -c icns "$ICONSET" -o "$CONTENTS/Resources/AppIcon.icns"
echo "  Icon created"

# ── Compile ────────────────────────────────────────────────────────────────
echo "→ Compiling Swift..."
swiftc \
    "$DIR/main.swift" \
    "$BUILD_DIR/html_resource.swift" \
    -o "$CONTENTS/MacOS/$APP_NAME" \
    -framework AppKit \
    -framework WebKit \
    -O

# ── Info.plist ─────────────────────────────────────────────────────────────
cat > "$CONTENTS/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>yoda</string>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key><true/>
</dict>
</plist>
PLIST

# ── Install ────────────────────────────────────────────────────────────────
echo "→ Installing to ~/Applications..."
rm -rf ~/Applications/"$APP_NAME.app"
cp -r "$APP_PATH" ~/Applications/

echo ""
echo "✓ Done — Yoda.app is in ~/Applications"
echo "  First launch: right-click → Open (one-time Gatekeeper bypass)"
echo "  Then drag it to your Dock."
