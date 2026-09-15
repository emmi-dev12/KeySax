import Foundation

enum Pitch {
    static let minMIDI = 36
    static let maxMIDI = 96

    static func frequency(midi: Int) -> Double {
        440.0 * pow(2.0, (Double(midi) - 69.0) / 12.0)
    }

    static func clamp(_ midi: Int) -> Int {
        min(max(midi, minMIDI), maxMIDI)
    }

    static func displayName(midi: Int, flats: Bool = false) -> String {
        let namesSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        let namesFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
        let names = flats ? namesFlats : namesSharps
        let pc = ((midi % 12) + 12) % 12
        let octave = midi / 12 - 1
        return "\(names[pc])\(octave)"
    }
}

enum ScaleKind: String, CaseIterable, Identifiable, Codable {
    case youtube
    case major
    case minor
    case pentatonicMajor
    case pentatonicMinor
    case blues
    case mixolydian
    case dorian
    case chromatic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .youtube: return "YouTube"
        case .major: return "Major"
        case .minor: return "Natural Minor"
        case .pentatonicMajor: return "Major Pentatonic"
        case .pentatonicMinor: return "Minor Pentatonic"
        case .blues: return "Blues"
        case .mixolydian: return "Mixolydian"
        case .dorian: return "Dorian"
        case .chromatic: return "Chromatic"
        }
    }

    /// Scale degrees for ten neighboring playable notes.
    var intervals: [Int] {
        switch self {
        case .youtube:
            return [0, 2, 4, 5, 7, 9, 10, 12, 14, 16]
        case .major:
            return [0, 2, 4, 5, 7, 9, 11, 12, 14, 16]
        case .minor:
            return [0, 2, 3, 5, 7, 8, 10, 12, 14, 15]
        case .pentatonicMajor:
            return [0, 2, 4, 7, 9, 12, 14, 16, 19, 21]
        case .pentatonicMinor:
            return [0, 3, 5, 7, 10, 12, 15, 17, 19, 22]
        case .blues:
            return [0, 3, 5, 6, 7, 10, 12, 15, 17, 18]
        case .mixolydian:
            return [0, 2, 4, 5, 7, 9, 10, 12, 14, 16]
        case .dorian:
            return [0, 2, 3, 5, 7, 9, 10, 12, 14, 15]
        case .chromatic:
            return [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        }
    }
}

enum RootNote: Int, CaseIterable, Identifiable, Codable {
    case c = 0, cSharp, d, dSharp, e, f, fSharp, g, gSharp, a, aSharp, b

    var id: Int { rawValue }

    var title: String {
        ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"][rawValue]
    }
}

struct PlayableKey: Identifiable, Equatable {
    let index: Int
    let label: String
    let midi: Int
    var caption: String? = nil
    var id: Int { index }

    var noteName: String { caption ?? Pitch.displayName(midi: midi) }
}

enum KeyboardLayout {
    static let defaultNoteLabels = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

    /// Physical ANSI key codes for a computer-keyboard piano (A-row).
    static let letterPiano: [UInt16: Int] = [
        0x00: 0,  // A  C
        0x0D: 1,  // W  C♯
        0x01: 2,  // S  D
        0x0E: 3,  // E  D♯
        0x02: 4,  // D  E
        0x03: 5,  // F  F
        0x11: 6,  // T  F♯
        0x05: 7,  // G  G
        0x10: 8,  // Y  G♯
        0x04: 9,  // H  A
        0x20: 10, // U  A♯
        0x26: 11, // J  B
        0x28: 12, // K  C
        0x22: 13, // I  C♯
        0x25: 14, // L  D
        0x1F: 15, // O  D♯
        0x29: 16, // ;  E
        0x23: 17  // P  F
    ]

    static func notes(
        scale: ScaleKind,
        root: RootNote,
        octave: Int,
        transpose: Int,
        count: Int = 10
    ) -> [Int] {
        let start = (octave + 1) * 12 + root.rawValue + transpose
        let steps = scale.intervals.filter { $0 < 12 }
        let pattern = steps.isEmpty ? Array(0..<12) : steps
        return (0..<count).map { i in
            let deg = pattern[i % pattern.count]
            let oct = i / pattern.count
            return Pitch.clamp(start + deg + 12 * oct)
        }
    }
}
