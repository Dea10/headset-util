# XM3Release

Suelta los Sony WH-1000XM3 cuando la Mac se bloquea o se duerme, para que otra Mac pueda tomarlos. No conecta nada ni toca el Bluetooth global (teclado y mouse siguen funcionando).

Arranca solo al iniciar sesión (LaunchAgent) y macOS lo reinicia si se cierra.

## Instalar (en cada Mac)

```bash
git clone git@github.com:Dea10/headset-util.git ~/Projects/headset-util
cd ~/Projects/headset-util
./install.sh
```

- Si no encuentra `swiftc`, instala antes las herramientas de desarrollo: `xcode-select --install`.
- La primera vez que bloquees la Mac, si macOS pide permiso de Bluetooth para **XM3Release**, dale Permitir. Al recompilar (correr `install.sh` otra vez) puede volver a pedirlo.
- Otra dirección MAC: `./install.sh XX:XX:XX:XX:XX:XX` (búscala con `system_profiler SPBluetoothDataType`).

**No muevas ni borres la carpeta después de instalar**: el log apunta a ella. Si la mueves, corre `./install.sh` de nuevo. Evita Escritorio, Documentos o iCloud, porque macOS restringe esas carpetas.

## Ver logs

Se escriben en `xm3-release.log`, en esta misma carpeta:

```bash
tail -f xm3-release.log
```

Al bloquear la Mac debe aparecer `bloqueo: audífonos desconectados`.

## Desinstalar

```bash
./uninstall.sh
```
