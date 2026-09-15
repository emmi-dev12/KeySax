import SwiftUI

enum KeyboardRow: String, CaseIterable, Identifiable, Codable {
    case numbers, qwerty, home, bottom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .numbers: return "1 – 0"
        case .qwerty: return "QWERTY"
        case .home: return "HOME"
        case .bottom: return "BOTTOM"
        }
    }

    var hint: String {
        switch self {
        case .numbers: return "Number row"
        case .qwerty: return "Q row"
        case .home: return "A row"
        case .bottom: return "Z row"
        }
    }

    var defaultVoice: VoiceID {
        switch self {
        case .numbers: return .alto
        case .qwerty: return .kalimba
        case .home: return .piano
        case .bottom: return .guitar
        }
    }

    var octaveDelta: Int {
        switch self {
        case .numbers: return 0
        case .qwerty: return 1
        case .home: return 0
        case .bottom: return -1
        }
    }
}

enum VoiceID: String, CaseIterable, Identifiable, Codable {
    case alto, tenor, bari, youtube
    case piano, rhodes
    case guitar
    case drums
    case kalimba, glass, chimes, musicBox, pad, thump

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alto: return "Alto Sax"
        case .tenor: return "Tenor Sax"
        case .bari: return "Bari Sax"
        case .youtube: return "YouTube Sax"
        case .piano: return "Piano"
        case .rhodes: return "Rhodes"
        case .guitar: return "Guitar"
        case .drums: return "Drums"
        case .kalimba: return "Kalimba"
        case .glass: return "Crystal Glass"
        case .chimes: return "Chimes"
        case .musicBox: return "Music Box"
        case .pad: return "Soft Pad"
        case .thump: return "Space Thump"
        }
    }

    var group: String {
        switch self {
        case .alto, .tenor, .bari, .youtube: return "Horns"
        case .piano, .rhodes: return "Keys"
        case .guitar: return "Strings"
        case .drums: return "Drums"
        case .kalimba, .glass, .chimes, .musicBox, .pad, .thump: return "ASMR"
        }
    }

    var loops: Bool {
        switch self {
        case .alto, .tenor, .bari, .youtube, .pad: return true
        default: return false
        }
    }

    var saxPreset: SaxPreset? {
        switch self {
        case .alto: return .alto
        case .tenor: return .tenor
        case .bari: return .bari
        case .youtube: return .youtube
        default: return nil
        }
    }

    var register: Int {
        switch self {
        case .guitar: return -12
        case .kalimba, .musicBox, .glass: return 12
        case .chimes: return 19
        default: return 0
        }
    }

    var accent: Color {
        switch self {
        case .alto: return Color(red: 0.88, green: 0.70, blue: 0.35)
        case .tenor: return Color(red: 0.82, green: 0.48, blue: 0.22)
        case .bari: return Color(red: 0.62, green: 0.38, blue: 0.72)
        case .youtube: return Color(red: 1.0, green: 0.38, blue: 0.22)
        case .piano: return Color(red: 0.92, green: 0.88, blue: 0.80)
        case .rhodes: return Color(red: 0.95, green: 0.72, blue: 0.42)
        case .guitar: return Color(red: 0.55, green: 0.32, blue: 0.16)
        case .drums: return Color(red: 0.92, green: 0.28, blue: 0.38)
        case .kalimba: return Color(red: 0.78, green: 0.62, blue: 0.38)
        case .glass: return Color(red: 0.62, green: 0.84, blue: 0.90)
        case .chimes: return Color(red: 0.75, green: 0.78, blue: 0.95)
        case .musicBox: return Color(red: 0.90, green: 0.58, blue: 0.62)
        case .pad: return Color(red: 0.55, green: 0.72, blue: 0.70)
        case .thump: return Color(red: 0.42, green: 0.36, blue: 0.78)
        }
    }

    static var groups: [(String, [VoiceID])] {
        [
            ("Horns", [.alto, .tenor, .bari, .youtube]),
            ("Keys", [.piano, .rhodes]),
            ("Strings", [.guitar]),
            ("Drums", [.drums]),
            ("ASMR", [.kalimba, .glass, .chimes, .musicBox, .pad, .thump])
        ]
    }
}
