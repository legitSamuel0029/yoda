#!/bin/bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

xcodegen generate --project "$DIR"

xcodebuild \
    -project "$DIR/Yoda.xcodeproj" \
    -scheme Yoda \
    -configuration Release \
    -derivedDataPath "$DIR/build" \
    CODE_SIGN_IDENTITY="-" \
    build

rm -rf ~/Applications/Yoda.app
ditto "$DIR/build/Build/Products/Release/Yoda.app" ~/Applications/Yoda.app

echo "✓ Yoda.app installed to ~/Applications"
