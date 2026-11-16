#!/bin/zsh
# Compila XM3Release.app, lo instala en ~/Applications y lo registra como LaunchAgent.
# Uso: ./install.sh [XX:XX:XX:XX:XX:XX]   (por defecto la MAC de los XM3)
set -euo pipefail
cd "$(dirname "$0")"

ADDRESS="${1:-38:18:4C:11:6C:2B}"
LABEL="com.local.xm3-release"
APP="$HOME/Applications/XM3Release.app"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "→ Compilando"
rm -rf build && mkdir -p build/XM3Release.app/Contents/MacOS
cp Info.plist build/XM3Release.app/Contents/Info.plist
swiftc -O -swift-version 5 \
    -framework AppKit -framework IOBluetooth \
    -o build/XM3Release.app/Contents/MacOS/XM3Release \
    Sources/main.swift

# Firma: usa un certificado si existe; si no, ad-hoc (al recompilar habrá que volver a permitir Bluetooth).
IDENTITY=$(security find-identity -v -p codesigning | awk -F'"' '/Apple Development|Developer ID/ {print $2; exit}')
codesign --force --sign "${IDENTITY:--}" --identifier "$LABEL" build/XM3Release.app

echo "→ Instalando en $APP"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
mkdir -p "$HOME/Applications" "$HOME/Library/LaunchAgents"
rm -rf "$APP" && cp -R build/XM3Release.app "$APP"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP/Contents/MacOS/XM3Release</string>
        <string>--address</string>
        <string>$ADDRESS</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>ProcessType</key><string>Interactive</string>
    <key>StandardOutPath</key><string>$PWD/xm3-release.log</string>
    <key>StandardErrorPath</key><string>$PWD/xm3-release.log</string>
</dict>
</plist>
EOF

launchctl bootstrap "gui/$(id -u)" "$PLIST"

# Alias xm3on / xm3off en ~/.zshrc, dentro de un bloque marcado para poder reemplazarlo o quitarlo.
ZSHRC="${ZSHRC:-$HOME/.zshrc}"
START="# >>> xm3-release aliases >>>"
END="# <<< xm3-release aliases <<<"
touch "$ZSHRC"
TMP=$(mktemp)
awk -v s="$START" -v e="$END" '$0==s{skip=1} !skip{print} $0==e{skip=0}' "$ZSHRC" > "$TMP"
cat >> "$TMP" <<EOF
$START
alias xm3off='$APP/Contents/MacOS/XM3Release --address $ADDRESS --release-now'
alias xm3on='$APP/Contents/MacOS/XM3Release --address $ADDRESS --connect-now'
$END
EOF
cat "$TMP" > "$ZSHRC" && rm -f "$TMP"   # cat > respeta si ~/.zshrc es un symlink
echo "→ Alias xm3on / xm3off en $ZSHRC (abre una Terminal nueva o corre: source ~/.zshrc)"

echo "✓ Instalado y corriendo. Si macOS pide permiso de Bluetooth para XM3Release, dale Permitir."
