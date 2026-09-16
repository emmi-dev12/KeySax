import AppKit
import ApplicationServices
import Darwin
import Foundation

@main
enum KeySaxKeysMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    var statusItem: NSStatusItem?
    var routeItem: NSMenuItem?
    var enabled = true
    var tap: CFMachPort?
    var serverFD: Int32 = -1
    let hub = SSEHub()
    var pingTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        setupMenu()
        startTap()
        startStatusServer()
        startPing()
        promptAccessibilityIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.ensureKeySaxInBackground()
            self?.refreshRouteStatus()
        }
    }

    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "🎷"
        statusItem?.button?.toolTip = "KeySax Keys — listener"
        let menu = NSMenu()
        let toggle = NSMenuItem(title: "Play keys in other apps", action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.state = .on
        toggle.target = self
        menu.addItem(toggle)
        let route = NSMenuItem(title: "Waiting for KeySax…", action: nil, keyEquivalent: "")
        route.isEnabled = false
        routeItem = route
        menu.addItem(route)
        menu.addItem(NSMenuItem(title: "Open KeySax", action: #selector(openKeySax), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Device Control & Data Access…", action: #selector(openAccessibility), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit KeySax Keys", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        enabled.toggle()
        sender.state = enabled ? .on : .off
        refreshRouteStatus()
    }

    @objc private func openKeySax() {
        if let app = runningKeySax().first {
            app.unhide()
            app.activate(options: [.activateIgnoringOtherApps])
            return
        }
        if let url = installedKeySaxApps().first {
            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: cfg)
            return
        }
        if let url = URL(string: "https://emmi-dev12.github.io/KeySax/") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openAccessibility() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func promptAccessibilityIfNeeded() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    private func ensureKeySaxInBackground() {
        if !runningKeySax().isEmpty { return }
        guard let url = installedKeySaxApps().first else { return }
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.activates = false
        cfg.addsToRecentItems = false
        NSWorkspace.shared.openApplication(at: url, configuration: cfg)
    }

    private func runningKeySax() -> [NSRunningApplication] {
        NSWorkspace.shared.runningApplications.filter { isInstalledKeySax($0) }
    }

    private func isInstalledKeySax(_ app: NSRunningApplication) -> Bool {
        let bid = app.bundleIdentifier ?? ""
        if bid == "dev.keysax.keys" { return false }
        if bid.hasPrefix("com.apple.WebKit") || bid.hasPrefix("com.apple.appkit") { return false }
        if let last = app.bundleURL?.lastPathComponent.lowercased(), last == "keysax.app" { return true }
        let name = app.localizedName ?? ""
        if bid.hasPrefix("com.apple.Safari.WebApp") && name.localizedCaseInsensitiveContains("keysax") { return true }
        if bid.hasPrefix("com.google.Chrome.app") && name.localizedCaseInsensitiveContains("keysax") { return true }
        return false
    }

    private func isKeySaxFrontmost() -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else { return false }
        return isInstalledKeySax(app)
    }

    private func installedKeySaxApps() -> [URL] {
        let paths = [
            NSHomeDirectory() + "/Applications/KeySax.app",
            "/Applications/KeySax.app"
        ]
        return paths.compactMap { path -> URL? in
            let url = URL(fileURLWithPath: path)
            guard let bid = Bundle(url: url)?.bundleIdentifier else { return nil }
            if bid == "dev.keysax.keys" { return nil }
            if bid.hasPrefix("com.apple.Safari.WebApp") { return url }
            if bid.hasPrefix("com.google.Chrome.app") { return url }
            return nil
        }
    }

    func refreshRouteStatus() {
        let n = hub.count
        let running = !runningKeySax().isEmpty
        if !enabled {
            routeItem?.title = "Listener paused"
        } else if n > 0 {
            routeItem?.title = "Routing keys to KeySax"
        } else if running {
            routeItem?.title = "KeySax is open — waiting to connect"
        } else {
            routeItem?.title = "Open KeySax to hear keys"
        }
    }

    private func startTap() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) | CGEventMask(1 << CGEventType.keyUp.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, _ in
                AppDelegate.shared?.handle(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        ) else { return }
        self.tap = tap
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput, let tap {
            CGEvent.tapEnable(tap: tap, enable: true)
            return
        }
        guard enabled else { return }
        guard type == .keyDown || type == .keyUp else { return }
        if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 { return }
        if event.flags.contains(.maskCommand) || event.flags.contains(.maskControl) { return }
        if isKeySaxFrontmost() { return }
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        guard let code = Self.codeMap[keyCode] else { return }
        let down = type == .keyDown
        let shift = event.flags.contains(.maskShift)
        let payload = "{\"code\":\"\(code)\",\"down\":\(down),\"shift\":\(shift)}"
        if hub.count > 0 {
            hub.send("data: \(payload)\n\n")
        } else if let app = runningKeySax().first {
            event.postToPid(app.processIdentifier)
        }
    }

    private static let codeMap: [UInt16: String] = [
        0x00: "KeyA", 0x01: "KeyS", 0x02: "KeyD", 0x03: "KeyF", 0x04: "KeyH",
        0x05: "KeyG", 0x06: "KeyZ", 0x07: "KeyX", 0x08: "KeyC", 0x09: "KeyV",
        0x0B: "KeyB", 0x0C: "KeyQ", 0x0D: "KeyW", 0x0E: "KeyE", 0x0F: "KeyR",
        0x10: "KeyY", 0x11: "KeyT", 0x12: "Digit1", 0x13: "Digit2", 0x14: "Digit3",
        0x15: "Digit4", 0x16: "Digit6", 0x17: "Digit5", 0x18: "Equal", 0x19: "Digit9",
        0x1A: "Digit7", 0x1B: "Minus", 0x1C: "Digit8", 0x1D: "Digit0", 0x1E: "BracketRight",
        0x1F: "KeyO", 0x20: "KeyU", 0x21: "BracketLeft", 0x22: "KeyI", 0x23: "KeyP",
        0x31: "Space",
        0x25: "KeyL", 0x26: "KeyJ", 0x27: "Quote", 0x28: "KeyK",
        0x29: "Semicolon", 0x2A: "Backslash", 0x2B: "Comma", 0x2C: "Slash", 0x2D: "KeyN",
        0x2E: "KeyM", 0x2F: "Period", 0x32: "Backquote",
        0x52: "Numpad0", 0x53: "Numpad1", 0x54: "Numpad2", 0x55: "Numpad3",
        0x56: "Numpad4", 0x57: "Numpad5", 0x58: "Numpad6", 0x59: "Numpad7",
        0x5B: "Numpad8", 0x5C: "Numpad9", 0x41: "NumpadDecimal", 0x45: "NumpadAdd",
        0x4E: "NumpadSubtract", 0x43: "NumpadMultiply", 0x4B: "NumpadDivide"
    ]

    private func startPing() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { [weak self] _ in
            self?.hub.send(": ping\n\n")
            self?.refreshRouteStatus()
        }
    }

    private func corsHeaders() -> String {
        "Access-Control-Allow-Origin: *\r\nAccess-Control-Allow-Methods: GET, OPTIONS\r\nAccess-Control-Allow-Headers: Content-Type\r\nAccess-Control-Allow-Private-Network: true\r\n"
    }

    private func startStatusServer() {
        serverFD = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        guard serverFD >= 0 else { return }
        var yes: Int32 = 1
        Darwin.setsockopt(serverFD, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))
        Darwin.setsockopt(serverFD, SOL_SOCKET, SO_NOSIGPIPE, &yes, socklen_t(MemoryLayout<Int32>.size))
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(18765).bigEndian
        addr.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
        let bindRes: Int32 = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { Darwin.bind(serverFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        guard bindRes == 0, Darwin.listen(serverFD, 16) == 0 else { return }
        DispatchQueue.global(qos: .utility).async {
            while let owner = AppDelegate.shared, owner.serverFD >= 0 {
                var clientAddr = sockaddr_in()
                var len = socklen_t(MemoryLayout<sockaddr_in>.size)
                let client: Int32 = withUnsafeMutablePointer(to: &clientAddr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { Darwin.accept(owner.serverFD, $0, &len) }
                }
                if client < 0 { continue }
                var nosig: Int32 = 1
                Darwin.setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &nosig, socklen_t(MemoryLayout<Int32>.size))
                var buf = [UInt8](repeating: 0, count: 2048)
                let n = Darwin.read(client, &buf, buf.count)
                let req = n > 0 ? String(bytes: buf.prefix(n), encoding: .utf8) ?? "" : ""
                let first = req.split(whereSeparator: { $0 == "\r" || $0 == "\n" }).first.map(String.init) ?? ""
                let parts = first.split(separator: " ").map(String.init)
                let method = parts.first ?? "GET"
                let rawPath = parts.dropFirst().first ?? "/"
                let path = String(rawPath.split(separator: "?").first ?? Substring(rawPath))
                if method == "OPTIONS" {
                    let res = "HTTP/1.1 204 No Content\r\n\(owner.corsHeaders())Connection: close\r\n\r\n"
                    res.withCString { _ = Darwin.write(client, $0, strlen($0)) }
                    Darwin.close(client)
                    continue
                }
                if path == "/keys" {
                    let res = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache, no-store\r\nConnection: keep-alive\r\n\(owner.corsHeaders())\r\nretry: 1000\n\n"
                    res.withCString { _ = Darwin.write(client, $0, strlen($0)) }
                    owner.hub.add(client)
                    DispatchQueue.main.async { owner.refreshRouteStatus() }
                    continue
                }
                let body = "{\"ok\":true,\"name\":\"KeySax Keys\",\"clients\":\(owner.hub.count)}"
                let res = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\(owner.corsHeaders())Content-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
                res.withCString { _ = Darwin.write(client, $0, strlen($0)) }
                Darwin.close(client)
            }
        }
    }
}

final class SSEHub {
    private let lock = NSLock()
    private var clients: [Int32] = []

    var count: Int {
        lock.lock(); defer { lock.unlock() }
        return clients.count
    }

    func add(_ fd: Int32) {
        lock.lock()
        clients.append(fd)
        lock.unlock()
    }

    func send(_ chunk: String) {
        lock.lock()
        let fds = clients
        lock.unlock()
        var dead: [Int32] = []
        for fd in fds {
            let n = chunk.withCString { Darwin.write(fd, $0, strlen($0)) }
            if n <= 0 { dead.append(fd) }
        }
        if !dead.isEmpty {
            lock.lock()
            clients.removeAll { dead.contains($0) }
            lock.unlock()
            dead.forEach { Darwin.close($0) }
        }
    }
}
