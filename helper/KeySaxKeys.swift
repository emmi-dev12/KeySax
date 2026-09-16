import AppKit
import WebKit
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

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    static var shared: AppDelegate?

    var statusItem: NSStatusItem?
    var webView: WKWebView!
    var pageReady = false
    var enabled = true
    var tap: CFMachPort?
    var serverFD: Int32 = -1

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        setupWebView()
        setupMenu()
        startTap()
        startStatusServer()
        promptAccessibilityIfNeeded()
    }

    private func setupWebView() {
        let cfg = WKWebViewConfiguration()
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.suppressesIncrementalRendering = false
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 700), configuration: cfg)
        webView.navigationDelegate = self
        let win = NSWindow(
            contentRect: NSRect(x: -4000, y: -4000, width: 900, height: 700),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        win.isReleasedWhenClosed = false
        win.contentView = webView
        win.orderBack(nil)
        if let url = URL(string: "https://emmi-dev12.github.io/KeySax/") {
            webView.load(URLRequest(url: url))
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("typeof unlock==='function'&&unlock();true;") { _, _ in
            self.pageReady = true
        }
    }

    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "🎷"
        statusItem?.button?.toolTip = "KeySax Keys"
        let menu = NSMenu()
        let toggle = NSMenuItem(title: "Play keys in other apps", action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.state = .on
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(NSMenuItem(title: "Open KeySax", action: #selector(openKeySax), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Accessibility settings…", action: #selector(openAccessibility), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit KeySax Keys", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        enabled.toggle()
        sender.state = enabled ? .on : .off
    }

    @objc private func openKeySax() {
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
        guard enabled, pageReady else { return }
        if type == .tapDisabledByTimeout, let tap {
            CGEvent.tapEnable(tap: tap, enable: true)
            return
        }
        guard type == .keyDown || type == .keyUp else { return }
        if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 { return }
        if isKeySaxFrontmost() { return }
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        guard let code = Self.codeMap[keyCode] else { return }
        let down = type == .keyDown
        let shift = event.flags.contains(.maskShift)
        let js = "window.keysaxFromHelper && window.keysaxFromHelper(\(Self.jsString(code)),\(down),\(shift))"
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func isKeySaxFrontmost() -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else { return false }
        let name = app.localizedName ?? ""
        let bid = app.bundleIdentifier ?? ""
        if name.localizedCaseInsensitiveContains("keysax") { return true }
        if bid.localizedCaseInsensitiveContains("keysax") { return true }
        return false
    }

    private static func jsString(_ s: String) -> String {
        "\"\(s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\""
    }

    private static let codeMap: [UInt16: String] = [
        0x00: "KeyA", 0x01: "KeyS", 0x02: "KeyD", 0x03: "KeyF", 0x04: "KeyH",
        0x05: "KeyG", 0x06: "KeyZ", 0x07: "KeyX", 0x08: "KeyC", 0x09: "KeyV",
        0x0B: "KeyB", 0x0C: "KeyQ", 0x0D: "KeyW", 0x0E: "KeyE", 0x0F: "KeyR",
        0x10: "KeyY", 0x11: "KeyT", 0x12: "Digit1", 0x13: "Digit2", 0x14: "Digit3",
        0x15: "Digit4", 0x16: "Digit6", 0x17: "Digit5", 0x18: "Equal", 0x19: "Digit9",
        0x1A: "Digit7", 0x1B: "Minus", 0x1C: "Digit8", 0x1D: "Digit0", 0x1E: "BracketRight",
        0x1F: "KeyO", 0x20: "KeyU", 0x21: "BracketLeft", 0x22: "KeyI", 0x23: "KeyP",
        0x24: "Enter", 0x25: "KeyL", 0x26: "KeyJ", 0x27: "Quote", 0x28: "KeyK",
        0x29: "Semicolon", 0x2A: "Backslash", 0x2B: "Comma", 0x2C: "Slash", 0x2D: "KeyN",
        0x2E: "KeyM", 0x2F: "Period", 0x32: "Backquote", 0x33: "Backspace", 0x35: "Escape",
        0x30: "Tab", 0x31: "Space",
        0x52: "Numpad0", 0x53: "Numpad1", 0x54: "Numpad2", 0x55: "Numpad3",
        0x56: "Numpad4", 0x57: "Numpad5", 0x58: "Numpad6", 0x59: "Numpad7",
        0x5B: "Numpad8", 0x5C: "Numpad9", 0x41: "NumpadDecimal", 0x45: "NumpadAdd",
        0x4E: "NumpadSubtract", 0x43: "NumpadMultiply", 0x4B: "NumpadDivide",
        0x4C: "NumpadEnter"
    ]

    private func startStatusServer() {
        serverFD = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        guard serverFD >= 0 else { return }
        var yes: Int32 = 1
        Darwin.setsockopt(serverFD, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(18765).bigEndian
        addr.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
        let bindRes: Int32 = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { Darwin.bind(serverFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        guard bindRes == 0, Darwin.listen(serverFD, 8) == 0 else { return }
        DispatchQueue.global(qos: .utility).async {
            while AppDelegate.shared?.serverFD ?? -1 >= 0 {
                guard let owner = AppDelegate.shared else { break }
                var clientAddr = sockaddr_in()
                var len = socklen_t(MemoryLayout<sockaddr_in>.size)
                let client: Int32 = withUnsafeMutablePointer(to: &clientAddr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { Darwin.accept(owner.serverFD, $0, &len) }
                }
                if client < 0 { continue }
                var buf = [UInt8](repeating: 0, count: 1024)
                _ = Darwin.read(client, &buf, buf.count)
                let body = "{\"ok\":true,\"name\":\"KeySax Keys\"}"
                let res = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
                res.withCString { _ = Darwin.write(client, $0, strlen($0)) }
                Darwin.close(client)
            }
        }
    }
}
