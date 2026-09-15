import Foundation
import AppKit

struct KeyMap: Codable, Equatable {
    var noteKeys: [String]
    var octaveDown: String
    var octaveUp: String
    var volumeDown: String
    var volumeUp: String
    var transposeDown: String
    var transposeUp: String
    var sustain: String
    var panic: String

    static let `default` = KeyMap(
        noteKeys: KeyboardLayout.defaultNoteLabels,
        octaveDown: "down",
        octaveUp: "up",
        volumeDown: "-",
        volumeUp: "=",
        transposeDown: "[",
        transposeUp: "]",
        sustain: "tab",
        panic: "escape"
    )

    func noteIndex(for token: String) -> Int? {
        noteKeys.firstIndex(where: { $0.caseInsensitiveCompare(token) == .orderedSame })
    }
}

enum KeyToken {
    static func from(event: NSEvent) -> String? {
        switch event.keyCode {
        case 53: return "escape"
        case 48: return "tab"
        case 49: return "space"
        case 125: return "down"
        case 126: return "up"
        case 123: return "left"
        case 124: return "right"
        default: break
        }
        guard let chars = event.charactersIgnoringModifiers, let first = chars.first else {
            return nil
        }
        let raw = String(first)
        if raw == "\u{1B}" { return "escape" }
        return raw.lowercased()
    }

    static func display(_ token: String) -> String {
        switch token.lowercased() {
        case "escape": return "Esc"
        case "tab": return "Tab"
        case "space": return "Space"
        case " ": return "Space"
        case "up": return "↑"
        case "down": return "↓"
        case "left": return "←"
        case "right": return "→"
        default: return token.uppercased()
        }
    }
}
