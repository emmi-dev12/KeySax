import Foundation
import SwiftUI

struct Formant: Hashable, Codable {
    var freq: Float
    var gain: Float
    var bandwidth: Float
}

enum ToneEngine: String, CaseIterable, Identifiable, Codable {
    case additive
    case reed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .additive: return "Classic Sax"
        case .reed: return "Reed Model"
        }
    }

    var subtitle: String {
        switch self {
        case .additive: return "Additive harmonics + breath"
        case .reed: return "Physical-model waveguide"
        }
    }
}

struct SaxPreset: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var blurb: String
    var formants: [Formant]
    var oddBoost: Float
    var evenBoost: Float
    var rolloff: Float
    var harmonicCount: Int
    var breath: Float
    var breathFreq: Float
    var chiff: Float
    var vibratoRate: Float
    var vibratoDepth: Float
    var vibratoDelay: Float
    var scoopCents: Float
    var brightness: Float
    var saturation: Float
    var growl: Float
    var ampVibrato: Float
    var defaultOctave: Int
    var tint: SaxTint

    enum SaxTint: String, Codable, Hashable {
        case alto, tenor, bari, youtube
    }

    static let all: [SaxPreset] = [.alto, .tenor, .bari, .youtube]

    static let alto = SaxPreset(
        id: "alto",
        name: "Alto Sax",
        blurb: "Bright, singing, the YouTube default horn.",
        formants: [
            Formant(freq: 820, gain: 2.6, bandwidth: 0.14),
            Formant(freq: 1480, gain: 1.7, bandwidth: 0.18),
            Formant(freq: 2650, gain: 1.25, bandwidth: 0.22),
            Formant(freq: 3800, gain: 0.7, bandwidth: 0.3)
        ],
        oddBoost: 1.05,
        evenBoost: 1.12,
        rolloff: 0.78,
        harmonicCount: 28,
        breath: 0.09,
        breathFreq: 2600,
        chiff: 0.22,
        vibratoRate: 5.3,
        vibratoDepth: 9,
        vibratoDelay: 0.28,
        scoopCents: 22,
        brightness: 0.62,
        saturation: 0.26,
        growl: 0.02,
        ampVibrato: 0.04,
        defaultOctave: 4,
        tint: .alto
    )

    static let tenor = SaxPreset(
        id: "tenor",
        name: "Tenor Sax",
        blurb: "Warm, smoky, a little more body.",
        formants: [
            Formant(freq: 520, gain: 2.8, bandwidth: 0.13),
            Formant(freq: 980, gain: 1.9, bandwidth: 0.18),
            Formant(freq: 2200, gain: 1.05, bandwidth: 0.24),
            Formant(freq: 3300, gain: 0.6, bandwidth: 0.32)
        ],
        oddBoost: 1.02,
        evenBoost: 1.18,
        rolloff: 0.7,
        harmonicCount: 26,
        breath: 0.1,
        breathFreq: 2100,
        chiff: 0.2,
        vibratoRate: 5.0,
        vibratoDepth: 11,
        vibratoDelay: 0.32,
        scoopCents: 26,
        brightness: 0.48,
        saturation: 0.3,
        growl: 0.05,
        ampVibrato: 0.045,
        defaultOctave: 3,
        tint: .tenor
    )

    static let bari = SaxPreset(
        id: "bari",
        name: "Bari Sax",
        blurb: "Foghorn low end with a reedy bark.",
        formants: [
            Formant(freq: 310, gain: 3.0, bandwidth: 0.12),
            Formant(freq: 640, gain: 1.8, bandwidth: 0.16),
            Formant(freq: 1750, gain: 0.95, bandwidth: 0.26),
            Formant(freq: 2800, gain: 0.5, bandwidth: 0.34)
        ],
        oddBoost: 1.0,
        evenBoost: 1.2,
        rolloff: 0.62,
        harmonicCount: 22,
        breath: 0.12,
        breathFreq: 1500,
        chiff: 0.24,
        vibratoRate: 4.6,
        vibratoDepth: 8,
        vibratoDelay: 0.34,
        scoopCents: 16,
        brightness: 0.34,
        saturation: 0.36,
        growl: 0.09,
        ampVibrato: 0.03,
        defaultOctave: 2,
        tint: .bari
    )

    static let youtube = SaxPreset(
        id: "youtube",
        name: "YouTube Sax",
        blurb: "Honk, scoop, extra vibrato. Comedy gold.",
        formants: [
            Formant(freq: 760, gain: 3.2, bandwidth: 0.1),
            Formant(freq: 1280, gain: 2.3, bandwidth: 0.14),
            Formant(freq: 2900, gain: 1.5, bandwidth: 0.18),
            Formant(freq: 4100, gain: 0.9, bandwidth: 0.24)
        ],
        oddBoost: 1.2,
        evenBoost: 0.95,
        rolloff: 0.68,
        harmonicCount: 30,
        breath: 0.14,
        breathFreq: 3000,
        chiff: 0.36,
        vibratoRate: 6.2,
        vibratoDepth: 22,
        vibratoDelay: 0.14,
        scoopCents: 70,
        brightness: 0.78,
        saturation: 0.42,
        growl: 0.1,
        ampVibrato: 0.08,
        defaultOctave: 4,
        tint: .youtube
    )

    static func named(_ id: String) -> SaxPreset {
        all.first(where: { $0.id == id }) ?? .alto
    }

    var accent: Color {
        switch tint {
        case .alto: return Color(red: 0.88, green: 0.70, blue: 0.35)
        case .tenor: return Color(red: 0.82, green: 0.48, blue: 0.22)
        case .bari: return Color(red: 0.62, green: 0.38, blue: 0.72)
        case .youtube: return Color(red: 1.0, green: 0.38, blue: 0.22)
        }
    }
}
