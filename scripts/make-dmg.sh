#!/bin/bash
# Builds dist/HandCursor-<version>.dmg: a window with the app and an Applications shortcut
# laid out so installing is one drag. Falls back to a plain DMG if Finder can't be scripted.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$ROOT"

"$ROOT/scripts/build-app.sh"
DMG="dist/$APP_NAME-$VERSION.dmg"
RW="dist/.rw.dmg"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE" "$RW"' EXIT

cp -R "dist/$APP_NAME.app" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
mkdir "$STAGE/.background"
cp assets/dmg/background.tiff "$STAGE/.background/background.tiff"

hdiutil detach "/Volumes/$APP_NAME" >/dev/null 2>&1 || true
rm -f "$RW" "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDRW -fs HFS+ "$RW" >/dev/null
hdiutil attach "$RW" -mountpoint "/Volumes/$APP_NAME" -nobrowse -noverify >/dev/null

if osascript <<OSA >/dev/null 2>&1
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 860, 520}
        set opts to the icon view options of container window
        set arrangement of opts to not arranged
        set icon size of opts to 112
        set background picture of opts to file ".background:background.tiff"
        set position of item "$APP_NAME.app" of container window to {170, 210}
        set position of item "Applications" of container window to {490, 210}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
OSA
then
    echo "Laid out the install window"
else
    echo "Note: couldn't script Finder; the DMG will open with the default layout"
fi

sync
hdiutil detach "/Volumes/$APP_NAME" >/dev/null || { sleep 2; hdiutil detach -force "/Volumes/$APP_NAME" >/dev/null; }
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
echo "Built $DMG"
