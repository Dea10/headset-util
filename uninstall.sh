#!/bin/zsh
set -euo pipefail
LABEL="com.local.xm3-release"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -rf "$HOME/Applications/XM3Release.app"
echo "✓ Desinstalado"
