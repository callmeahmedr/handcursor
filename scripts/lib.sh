#!/bin/bash
# Shared settings for the build scripts. Rename the app by editing this file and Sources/HandCursor/AppInfo.swift.

APP_NAME="HandCursor"
BUNDLE_ID="io.github.callmeahmedr.handcursor"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${HANDCURSOR_VERSION:-$(tr -d '[:space:]' < "$ROOT/VERSION")}"

quit_running_app() {
    if pgrep -x "$APP_NAME" >/dev/null; then
        echo "Quitting the running $APP_NAME first..."
        osascript -e "quit app id \"$BUNDLE_ID\"" >/dev/null 2>&1 || true
        sleep 1
        pkill -x "$APP_NAME" || true
        sleep 0.5
    fi
}

make_bundle() {
    local binary="$1" app="$2"
    rm -rf "$app"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    cp "$binary" "$app/Contents/MacOS/$APP_NAME"
    cp "$ROOT"/assets/hand_*.png "$ROOT"/assets/menubar_*.png "$ROOT/assets/AppIcon.icns" "$app/Contents/Resources/"
    cp "$ROOT"/assets/sounds/tap_*.wav "$app/Contents/Resources/"

    cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER:-1}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>$BUNDLE_ID</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>handcursor</string>
            </array>
        </dict>
    </array>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHumanReadableCopyright</key>
    <string>MIT License. A for-fun rebuild of TinyHand by Kamran Ahmed.</string>
</dict>
</plist>
PLIST
}

# Ad-hoc signature: enough for the app to run (Apple Silicon requires one). People who download a
# build may need to right-click > Open the first time, because it isn't notarized.
sign_app() {
    codesign --force --deep --sign "${CODESIGN_IDENTITY:--}" "$1"
    codesign --verify --deep --strict "$1"
}
