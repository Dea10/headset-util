// XM3Release: suelta los Sony WH-1000XM3 cuando la Mac se bloquea o se duerme.
// No conecta nada, no toca el Bluetooth global, solo desconecta esa dirección MAC.

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

// Uso: XM3Release [--address XX:XX:XX:XX:XX:XX] [--release-now]
var address = defaultAddress
var releaseNow = false
var args = CommandLine.arguments.dropFirst().makeIterator()
while let arg = args.next() {
    switch arg {
    case "--address": if let a = args.next() { address = a }
    case "--release-now": releaseNow = true
    default:
        FileHandle.standardError.write("Argumento desconocido: \(arg)\n".data(using: .utf8)!)
        exit(2)
    }
}

func release(reason: String) {
    guard let device = IOBluetoothDevice(addressString: address) else {
        say("Dirección inválida o dispositivo no emparejado: \(address)", error: true)
        return
    }
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

if releaseNow {
    release(reason: "manual")
    exit(0)
}

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: .main
) { _ in release(reason: "bloqueo") }

NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
) { _ in release(reason: "suspensión") }

say("Escuchando bloqueo/suspensión para \(address)")

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
app.run()
