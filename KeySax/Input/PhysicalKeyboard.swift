import Foundation
import AppKit
import Carbon

enum PhysicalKeyboard {
    static let numbers: [UInt16] = [
        0x32, 0x12, 0x13, 0x14, 0x15, 0x17, 0x16, 0x1A, 0x1C, 0x19, 0x1D, 0x1B, 0x18
    ]
    static let qwerty: [UInt16] = [
        0x0C, 0x0D, 0x0E, 0x0F, 0x11, 0x10, 0x20, 0x22, 0x1F, 0x23, 0x21, 0x1E, 0x2A
    ]
    static let home: [UInt16] = [
        0x00, 0x01, 0x02, 0x03, 0x05, 0x04, 0x26, 0x28, 0x25, 0x29, 0x27
    ]
    static let bottom: [UInt16] = [
        0x06, 0x07, 0x08, 0x09, 0x0B, 0x2D, 0x2E, 0x2B, 0x2F, 0x2C
    ]

    static func codes(for row: KeyboardRow) -> [UInt16] {
        switch row {
        case .numbers: return numbers
        case .qwerty: return qwerty
        case .home: return home
        case .bottom: return bottom
        }
    }

    static let lookup: [UInt16: (KeyboardRow, Int)] = {
        var map: [UInt16: (KeyboardRow, Int)] = [:]
        for row in KeyboardRow.allCases {
            for (i, code) in codes(for: row).enumerated() {
                map[code] = (row, i)
            }
        }
        return map
    }()

    static func glyph(forKeyCode keyCode: UInt16) -> String {
        typedGlyph(forKeyCode: keyCode, shift: false).uppercased()
    }

    static func typedGlyph(forKeyCode keyCode: UInt16, shift: Bool) -> String {
        if let live = translate(keyCode: keyCode, shift: shift), !live.isEmpty {
            return live
        }
        let table = shift ? abcShifted : abcFallback
        return table[keyCode] ?? "?"
    }

    private static func translate(keyCode: UInt16, shift: Bool) -> String? {
        let source = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
        guard let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        let data = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue() as Data
        return data.withUnsafeBytes { ptr -> String? in
            guard let layout = ptr.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else {
                return nil
            }
            var deadKeys: UInt32 = 0
            var chars: [UniChar] = [0, 0, 0, 0]
            var length = 0
            let mods: UInt32 = shift ? UInt32((shiftKey >> 8) & 0xFF) : 0
            let status = UCKeyTranslate(
                layout,
                keyCode,
                UInt16(kUCKeyActionDown),
                mods,
                UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit),
                &deadKeys,
                4,
                &length,
                &chars
            )
            guard status == noErr, length > 0 else { return nil }
            let s = String(utf16CodeUnits: chars, count: length)
            if s.isEmpty { return nil }
            return s
        }
    }

    private static let abcFallback: [UInt16: String] = [
        0x32: "`", 0x12: "1", 0x13: "2", 0x14: "3", 0x15: "4", 0x17: "5",
        0x16: "6", 0x1A: "7", 0x1C: "8", 0x19: "9", 0x1D: "0", 0x1B: "-", 0x18: "=",
        0x0C: "q", 0x0D: "w", 0x0E: "e", 0x0F: "r", 0x11: "t",
        0x10: "y", 0x20: "u", 0x22: "i", 0x1F: "o", 0x23: "p", 0x21: "[", 0x1E: "]", 0x2A: "\\",
        0x00: "a", 0x01: "s", 0x02: "d", 0x03: "f", 0x05: "g",
        0x04: "h", 0x26: "j", 0x28: "k", 0x25: "l", 0x29: ";", 0x27: "'",
        0x06: "z", 0x07: "x", 0x08: "c", 0x09: "v", 0x0B: "b",
        0x2D: "n", 0x2E: "m", 0x2B: ",", 0x2F: ".", 0x2C: "/"
    ]

    private static let abcShifted: [UInt16: String] = [
        0x32: "~", 0x12: "!", 0x13: "@", 0x14: "#", 0x15: "$", 0x17: "%",
        0x16: "^", 0x1A: "&", 0x1C: "*", 0x19: "(", 0x1D: ")", 0x1B: "_", 0x18: "+",
        0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R", 0x11: "T",
        0x10: "Y", 0x20: "U", 0x22: "I", 0x1F: "O", 0x23: "P", 0x21: "{", 0x1E: "}", 0x2A: "|",
        0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x05: "G",
        0x04: "H", 0x26: "J", 0x28: "K", 0x25: "L", 0x29: ":", 0x27: "\"",
        0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V", 0x0B: "B",
        0x2D: "N", 0x2E: "M", 0x2B: "<", 0x2F: ">", 0x2C: "?"
    ]
}
