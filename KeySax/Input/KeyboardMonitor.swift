import AppKit
import SwiftUI

@MainActor
final class KeyboardMonitor {
    private var local: Any?
    private var flags: Any?

    var onDown: ((String, NSEvent) -> Bool)?
    var onUp: ((String, NSEvent) -> Bool)?
    var isTypingField: () -> Bool = { false }

    func start() {
        stop()
        local = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self else { return event }
            if self.isTypingField() { return event }
            if Self.isSystemShortcut(event) {
                if event.type == .keyUp, let token = KeyToken.from(event: event) {
                    _ = self.onUp?(token, event)
                }
                return event
            }
            if event.type == .keyDown, event.isARepeat { return nil }
            guard let token = KeyToken.from(event: event) else { return event }
            let consumed: Bool
            if event.type == .keyDown {
                consumed = self.onDown?(token, event) ?? false
            } else {
                consumed = self.onUp?(token, event) ?? false
            }
            return consumed ? nil : event
        }
    }

    func stop() {
        if let local {
            NSEvent.removeMonitor(local)
            self.local = nil
        }
        if let flags {
            NSEvent.removeMonitor(flags)
            self.flags = nil
        }
    }

    /// ⌘ / ⌃ chords belong to macOS and the menu bar, not the instrument.
    private static func isSystemShortcut(_ event: NSEvent) -> Bool {
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return mods.contains(.command) || mods.contains(.control)
    }
}

enum TypingFocus {
    static func isTextInput() -> Bool {
        guard let view = NSApp.keyWindow?.firstResponder else { return false }
        if view is NSTextView || view is NSTextField { return true }
        if String(describing: type(of: view)).contains("Text") { return true }
        return false
    }
}
