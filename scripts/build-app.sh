#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
configuration="${1:-release}"
source scripts/toolchain.sh
xcrun swift build -c "$configuration" --scratch-path .build/xcode --cache-path .build/cache
binary_dir=$(xcrun swift build -c "$configuration" --scratch-path .build/xcode --cache-path .build/cache --show-bin-path)
app_path="$PWD/build/Linear Focus.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp "$binary_dir/LinearFocus" "$app_path/Contents/MacOS/LinearFocus"
cp Resources/Info.plist "$app_path/Contents/Info.plist"
xcrun swift scripts/make-icon.swift "$PWD/.build/AppIcon.iconset"
iconutil -c icns "$PWD/.build/AppIcon.iconset" -o "$app_path/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$app_path"
printf '\nBuilt: %s\n' "$app_path"
