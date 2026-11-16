#!/bin/zsh
set -euo pipefail
LABEL="com.local.xm3-release"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -rf "$HOME/Applications/XM3Release.app"

# Quita el bloque de alias que agregó install.sh.
ZSHRC="${ZSHRC:-$HOME/.zshrc}"
if [[ -f "$ZSHRC" ]]; then
    TMP=$(mktemp)
    awk -v s="# >>> xm3-release aliases >>>" -v e="# <<< xm3-release aliases <<<" \
        '$0==s{skip=1} !skip{print} $0==e{skip=0}' "$ZSHRC" > "$TMP"
    cat "$TMP" > "$ZSHRC" && rm -f "$TMP"
fi
echo "✓ Desinstalado"
