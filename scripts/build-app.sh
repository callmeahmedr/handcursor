#!/bin/bash
# Builds dist/HandCursor.app (universal: Apple Silicon + Intel).
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$ROOT"

swift build -c release --arch arm64 --arch x86_64
APP="dist/$APP_NAME.app"
mkdir -p dist
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/$APP_NAME"
make_bundle "$BIN" "$APP"
sign_app "$APP"
lipo -info "$APP/Contents/MacOS/$APP_NAME"
echo "Built $APP $VERSION"
