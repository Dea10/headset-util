# XM3Release

Suelta los Sony WH-1000XM3 cuando la Mac se bloquea o se duerme, para que otra Mac pueda tomarlos, y los vuelve a conectar cuando la desbloqueas. No toca el Bluetooth global (teclado y mouse siguen funcionando).

Al desbloquear espera 2 segundos y lo intenta hasta 3 veces. Si los audífonos están apagados o fuera de alcance, se rinde y solo lo anota en el log; si los prendes después, conéctalos a mano. Si bloqueas otra vez mientras está intentando, cancela el intento.

Arranca solo al iniciar sesión (LaunchAgent) y macOS lo reinicia si se cierra.

## Instalar (en cada Mac)

```bash
git clone https://github.com/Dea10/headset-util.git ~/Projects/headset-util
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

Al bloquear la Mac debe aparecer `bloqueo: audífonos desconectados`, y al desbloquear `desbloqueo: audífonos conectados` (o `audífonos no disponibles` si están apagados).

## Conectar o soltar a mano

`install.sh` agrega dos alias a `~/.zshrc` (en un bloque marcado `xm3-release aliases`, que se reemplaza al reinstalar y se quita al desinstalar):

```bash
xm3on    # conecta los audífonos ahora (hasta 3 intentos)
xm3off   # los suelta ahora
```

Funcionan en cualquier Terminal nueva, o en una abierta después de `source ~/.zshrc`. El resultado sale en la Terminal, no en el log, y la primera vez macOS puede pedir permiso de Bluetooth para la Terminal.

## Desinstalar

Quita el servicio, la app y los alias de `~/.zshrc`:

```bash
./uninstall.sh
```
