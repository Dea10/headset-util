// XM3Release: suelta los Sony WH-1000XM3 cuando la Mac se bloquea o se duerme,
// y los vuelve a conectar al desbloquear. No toca el Bluetooth global, solo esa dirección MAC.

import AppKit
import IOBluetooth
import os

let logger = Logger(subsystem: "com.local.xm3-release", category: "main")
let defaultAddress = "38:18:4C:11:6C:2B"
let timestamp: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return f
}()

// Escribe al log del sistema y a stdout (launchd lo manda a xm3-release.log en la carpeta del proyecto).
func say(_ message: String, error: Bool = false) {
    if error { logger.error("\(message, privacy: .public)") } else { logger.notice("\(message, privacy: .public)") }
    FileHandle.standardOutput.write("\(timestamp.string(from: Date()))  \(message)\n".data(using: .utf8)!)
}

// Uso: XM3Release [--address XX:XX:XX:XX:XX:XX] [--release-now | --connect-now]
var address = defaultAddress
var releaseNow = false
var connectNow = false
var args = CommandLine.arguments.dropFirst().makeIterator()
while let arg = args.next() {
    switch arg {
    case "--address": if let a = args.next() { address = a }
    case "--release-now": releaseNow = true
    case "--connect-now": connectNow = true
    default:
        FileHandle.standardError.write("Argumento desconocido: \(arg)\n".data(using: .utf8)!)
        exit(2)
    }
}

func pairedDevice() -> IOBluetoothDevice? {
    guard let device = IOBluetoothDevice(addressString: address) else {
        say("Dirección inválida o dispositivo no emparejado: \(address)", error: true)
        return nil
    }
    return device
}

func release(reason: String) {
    guard let device = pairedDevice() else { return }
    guard device.isConnected() else {
        say("\(reason): audífonos no conectados, nada que hacer")
        return
    }
    let result = device.closeConnection()
    if result == kIOReturnSuccess {
        say("\(reason): audífonos desconectados")
    } else {
        say("\(reason): closeConnection falló (IOReturn \(result))", error: true)
    }
}

// Conecta los audífonos con unos pocos reintentos y luego se rinde (p. ej. si están apagados).
// Usa la conexión asíncrona para no congelar la app mientras macOS los busca.
// Cada bloqueo/suspensión sube `generation`, lo que cancela cualquier intento pendiente.
final class Connector: NSObject {
    let initialDelay: TimeInterval = 2
    let retryDelay: TimeInterval = 3
    let maxAttempts = 3

    private var generation = 0
    private var attempt = 0
    private var reason = ""
    private var inFlight: Int?   // generación del intento que espera respuesta de macOS
    var onFinish: (() -> Void)?

    func cancel() { generation += 1 }

    func start(reason: String, delay: TimeInterval? = nil) {
        generation += 1
        attempt = 0
        self.reason = reason
        schedule(after: delay ?? initialDelay)
    }

    private func schedule(after delay: TimeInterval) {
        let gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in tryConnect(gen) }
    }

    private func finish(_ message: String, error: Bool = false) {
        say("\(reason): \(message)", error: error)
        onFinish?()
    }

    private func tryConnect(_ gen: Int) {
        guard gen == generation else { return }   // se bloqueó mientras esperábamos
        guard inFlight == nil else { return }       // ya hay un intento en curso
        guard let device = pairedDevice() else { onFinish?(); return }
        if device.isConnected() { finish("audífonos ya conectados"); return }

        attempt += 1
        inFlight = gen
        let result = device.openConnection(self)
        if result != kIOReturnSuccess {
            inFlight = nil
            failed(gen, status: result)
        }
    }

    // Callback de IOBluetooth cuando termina openConnection(_ target:).
    @objc func connectionComplete(_ device: IOBluetoothDevice!, status: IOReturn) {
        let gen = inFlight
        inFlight = nil
        guard gen == generation else {
            // Se bloqueó/durmió mientras conectaba: no dejarlos conectados.
            if status == kIOReturnSuccess { device.closeConnection() }
            return
        }
        if status == kIOReturnSuccess {
            finish("audífonos conectados")
        } else {
            failed(generation, status: status)
        }
    }

    private func failed(_ gen: Int, status: IOReturn) {
        if attempt < maxAttempts {
            schedule(after: retryDelay)
        } else {
            finish("audífonos no disponibles (apagados o fuera de alcance; IOReturn \(status))")
        }
    }
}

let connector = Connector()

if releaseNow {
    release(reason: "manual")
    exit(0)
}

if connectNow {
    connector.onFinish = { exit(0) }
    connector.start(reason: "manual", delay: 0)
    RunLoop.main.run()
}

func onLockOrSleep(reason: String) {
    connector.cancel()
    release(reason: reason)
}

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: .main
) { _ in onLockOrSleep(reason: "bloqueo") }

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main
) { _ in connector.start(reason: "desbloqueo") }

NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
) { _ in onLockOrSleep(reason: "suspensión") }

say("Escuchando bloqueo/desbloqueo/suspensión para \(address)")

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
app.run()
