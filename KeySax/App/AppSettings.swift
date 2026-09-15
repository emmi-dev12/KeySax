import Foundation
import SwiftUI

@Observable
final class AppSettings {
    var volume: Double
    var sustain: Bool
    var octave: Int
    var transpose: Int
    var root: RootNote
    var scale: ScaleKind
    var presetID: String
    var engine: ToneEngine
    var letterMode: Bool
    var rowVoices: [String: String]
    var rowOctaves: [String: Int]
    var rowTransposes: [String: Int]
    var midiEnabled: Bool
    var midiDestination: Int
    var appearance: AppearanceMode
    var keyMap: KeyMap
    var letterVideo: Bool

    enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
        case system, dark, light
        var id: String { rawValue }
        var title: String {
            switch self {
            case .system: return "System"
            case .dark: return "Dark"
            case .light: return "Light"
            }
        }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .dark: return .dark
            case .light: return .light
            }
        }
    }

    init() {
        let d = UserDefaults.standard
        volume = d.object(forKey: Keys.volume) as? Double ?? 0.85
        sustain = d.bool(forKey: Keys.sustain)
        octave = d.object(forKey: Keys.octave) as? Int ?? 4
        transpose = d.integer(forKey: Keys.transpose)
        root = RootNote(rawValue: d.integer(forKey: Keys.root)) ?? .c
        scale = ScaleKind(rawValue: d.string(forKey: Keys.scale) ?? "") ?? .youtube
        presetID = d.string(forKey: Keys.preset) ?? SaxPreset.alto.id
        engine = ToneEngine(rawValue: d.string(forKey: Keys.engine) ?? "") ?? .additive
        letterMode = d.bool(forKey: Keys.letterMode)
        midiEnabled = d.bool(forKey: Keys.midi)
        midiDestination = d.integer(forKey: Keys.midiDest)
        appearance = AppearanceMode(rawValue: d.string(forKey: Keys.appearance) ?? "") ?? .dark
        letterVideo = d.object(forKey: Keys.letterVideo) as? Bool ?? true
        if let data = d.data(forKey: Keys.rowVoices),
           let map = try? JSONDecoder().decode([String: String].self, from: data) {
            rowVoices = map
        } else {
            rowVoices = [:]
        }
        if let data = d.data(forKey: Keys.rowOctaves),
           let map = try? JSONDecoder().decode([String: Int].self, from: data) {
            rowOctaves = map
        } else {
            rowOctaves = [:]
        }
        if let data = d.data(forKey: Keys.rowTransposes),
           let map = try? JSONDecoder().decode([String: Int].self, from: data) {
            rowTransposes = map
        } else {
            rowTransposes = [:]
        }
        if let data = d.data(forKey: Keys.keyMap),
           let map = try? JSONDecoder().decode(KeyMap.self, from: data) {
            keyMap = map
            if keyMap.octaveDown == "z" || keyMap.octaveUp == "x" {
                keyMap.octaveDown = "down"
                keyMap.octaveUp = "up"
            }
        } else {
            keyMap = .default
        }
        octave = min(6, max(1, octave))
        volume = min(1, max(0, volume))
    }

    func persist() {
        let d = UserDefaults.standard
        d.set(volume, forKey: Keys.volume)
        d.set(sustain, forKey: Keys.sustain)
        d.set(octave, forKey: Keys.octave)
        d.set(transpose, forKey: Keys.transpose)
        d.set(root.rawValue, forKey: Keys.root)
        d.set(scale.rawValue, forKey: Keys.scale)
        d.set(presetID, forKey: Keys.preset)
        d.set(engine.rawValue, forKey: Keys.engine)
        d.set(letterMode, forKey: Keys.letterMode)
        d.set(midiEnabled, forKey: Keys.midi)
        d.set(midiDestination, forKey: Keys.midiDest)
        d.set(appearance.rawValue, forKey: Keys.appearance)
        d.set(letterVideo, forKey: Keys.letterVideo)
        if let data = try? JSONEncoder().encode(keyMap) {
            d.set(data, forKey: Keys.keyMap)
        }
        if let data = try? JSONEncoder().encode(rowVoices) {
            d.set(data, forKey: Keys.rowVoices)
        }
        if let data = try? JSONEncoder().encode(rowOctaves) {
            d.set(data, forKey: Keys.rowOctaves)
        }
        if let data = try? JSONEncoder().encode(rowTransposes) {
            d.set(data, forKey: Keys.rowTransposes)
        }
    }

    func voice(for row: KeyboardRow) -> VoiceID {
        if let raw = rowVoices[row.rawValue], let voice = VoiceID(rawValue: raw) {
            return voice
        }
        return row.defaultVoice
    }

    func setVoice(_ voice: VoiceID, for row: KeyboardRow) {
        rowVoices[row.rawValue] = voice.rawValue
        persist()
    }

    func octave(for row: KeyboardRow) -> Int {
        min(7, max(1, rowOctaves[row.rawValue] ?? octave))
    }

    func setOctave(_ value: Int, for row: KeyboardRow) {
        rowOctaves[row.rawValue] = min(7, max(1, value))
        persist()
    }

    func transpose(for row: KeyboardRow) -> Int {
        min(12, max(-12, rowTransposes[row.rawValue] ?? transpose))
    }

    func setTranspose(_ value: Int, for row: KeyboardRow) {
        rowTransposes[row.rawValue] = min(12, max(-12, value))
        persist()
    }

    var preset: SaxPreset { SaxPreset.named(presetID) }

    func bumpOctave(_ delta: Int) {
        for row in KeyboardRow.allCases {
            setOctave(octave(for: row) + delta, for: row)
        }
        octave = min(7, max(1, octave + delta))
        persist()
    }

    func bumpTranspose(_ delta: Int) {
        for row in KeyboardRow.allCases {
            setTranspose(transpose(for: row) + delta, for: row)
        }
        transpose = min(12, max(-12, transpose + delta))
        persist()
    }

    func bumpVolume(_ delta: Double) {
        volume = min(1, max(0, volume + delta))
        persist()
    }

    private enum Keys {
        static let volume = "keysax.volume"
        static let sustain = "keysax.sustain"
        static let octave = "keysax.octave"
        static let transpose = "keysax.transpose"
        static let root = "keysax.root"
        static let scale = "keysax.scale"
        static let preset = "keysax.preset"
        static let engine = "keysax.engine"
        static let letterMode = "keysax.letterMode"
        static let midi = "keysax.midi"
        static let midiDest = "keysax.midiDest"
        static let appearance = "keysax.appearance"
        static let keyMap = "keysax.keyMap"
        static let rowVoices = "keysax.rowVoices"
        static let letterVideo = "keysax.letterVideo"
        static let rowOctaves = "keysax.rowOctaves"
        static let rowTransposes = "keysax.rowTransposes"
    }
}
