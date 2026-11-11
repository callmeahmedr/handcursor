#!/bin/bash
# Builds the app and installs it into /Applications.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$ROOT"

"$ROOT/scripts/build-app.sh"
quit_running_app
rm -rf "/Applications/$APP_NAME.app"
cp -R "dist/$APP_NAME.app" "/Applications/$APP_NAME.app"
open "/Applications/$APP_NAME.app"
echo "Installed /Applications/$APP_NAME.app"
