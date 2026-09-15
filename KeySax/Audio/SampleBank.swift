import Foundation
import AVFoundation

struct RenderedNote {
    let midi: Int
    let variant: Int
    let attack: AVAudioPCMBuffer
    let loop: AVAudioPCMBuffer
}

final class SampleBank: @unchecked Sendable {
    static let cacheVersion = "v8"

    private let lock = NSLock()
    private var banks: [String: [String: RenderedNote]] = [:]
    private var ready: Set<String> = []
    private(set) var format: AVAudioFormat

    init(format: AVAudioFormat) {
        self.format = format
    }

    var isReady: Bool { !ready.isEmpty }

    func isReady(_ voice: VoiceID) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return ready.contains(voice.rawValue)
    }

    func note(voice: VoiceID, midi: Int, variant: Int) -> RenderedNote? {
        lock.lock()
        defer { lock.unlock() }
        let bank = banks[voice.rawValue] ?? [:]
        if let hit = bank[key(midi, variant)] { return hit }
        let clamped = bank.keys.compactMap { Int($0.split(separator: "-").first ?? "") }
        guard let nearest = clamped.min(by: { abs($0 - midi) < abs($1 - midi) }) else { return nil }
        return bank[key(nearest, 0)] ?? bank[key(nearest, variant)]
    }

    func randomVariant(for voice: VoiceID) -> Int {
        switch voice {
        case .alto, .tenor, .bari, .youtube, .guitar, .thump, .drums:
            return Int.random(in: 0...1)
        default:
            return 0
        }
    }

    private func key(_ midi: Int, _ variant: Int) -> String { "\(midi)-\(variant)" }

    func ensure(
        voices: [VoiceID],
        engine: ToneEngine,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws {
        let unique = Array(Set(voices))
        for (i, voice) in unique.enumerated() {
            if isReady(voice) {
                progress(Double(i + 1) / Double(unique.count), voice.title)
                continue
            }
            try await generate(voice: voice, engine: engine) { p, s in
                let base = Double(i) / Double(unique.count)
                progress(base + p / Double(unique.count), s)
            }
        }
        progress(1, "Ready")
    }

    private func generate(
        voice: VoiceID,
        engine: ToneEngine,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws {
        let sr = Int(format.sampleRate.rounded())
        let kind: String
        if let preset = voice.saxPreset {
            kind = "\(engine.rawValue)-\(preset.id)"
        } else {
            kind = voice.rawValue
        }
        let dir = Self.cacheDir(kind: kind, sampleRate: sr)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let (notes, variants, looping) = spec(for: voice)
        let built = try await renderAll(
            notes: notes,
            variants: variants,
            dir: dir,
            label: voice.title,
            progress: progress
        ) { midi, variant in
            self.render(voice: voice, engine: engine, midi: midi, variant: variant, sr: sr)
        }

        var mapped: [String: RenderedNote] = [:]
        let empty = DSP.makePCMBuffer(mono: [0, 0, 0, 0], format: format)
        for (midi, variant, samples) in built {
            if looping {
                let split = LoopSplitter.split(
                    samples: samples,
                    sampleRate: Float(sr),
                    attackTime: voice == .pad ? 0.28 : 0.22,
                    loopCycles: 3,
                    vibratoRate: voice.saxPreset?.vibratoRate ?? 5.2
                )
                guard
                    let attack = DSP.makePCMBuffer(mono: split.attack, format: format),
                    let loop = DSP.makePCMBuffer(mono: split.loop, format: format)
                else { continue }
                mapped[key(midi, variant)] = RenderedNote(midi: midi, variant: variant, attack: attack, loop: loop)
            } else {
                guard let attack = DSP.makePCMBuffer(mono: samples, format: format) else { continue }
                mapped[key(midi, variant)] = RenderedNote(
                    midi: midi,
                    variant: variant,
                    attack: attack,
                    loop: empty ?? attack
                )
            }
        }
        store(voice: voice, mapped)
    }

    private func spec(for voice: VoiceID) -> (notes: [Int], variants: Int, looping: Bool) {
        switch voice {
        case .alto, .tenor, .bari, .youtube:
            return (Array(36...96), 2, true)
        case .piano:
            return (Array(36...96), 1, false)
        case .guitar:
            return (Array(40...88), 2, false)
        case .drums:
            return (Array(36...48), 2, false)
        case .kalimba:
            return (Array(48...96), 1, false)
        case .rhodes:
            return (Array(36...84), 1, false)
        case .glass:
            return (Array(48...96), 1, false)
        case .chimes:
            return (Array(60...96), 1, false)
        case .musicBox:
            return (Array(60...96), 1, false)
        case .pad:
            return (Array(36...84), 1, true)
        case .thump:
            return (Array(24...48), 2, false)
        }
    }

    private func render(voice: VoiceID, engine: ToneEngine, midi: Int, variant: Int, sr: Int) -> [Float] {
        let rate = Float(sr)
        if let preset = voice.saxPreset {
            switch engine {
            case .additive:
                return SaxSynthesizer.render(midi: midi, sampleRate: rate, preset: preset, variant: variant)
            case .reed:
                return ReedSynthesizer.render(midi: midi, sampleRate: rate, preset: preset, variant: variant)
            }
        }
        switch voice {
        case .piano:
            return PianoSynthesizer.render(midi: midi, sampleRate: rate, variant: variant)
        case .guitar:
            return GuitarSynthesizer.render(midi: midi, sampleRate: rate, variant: variant)
        case .drums:
            return DrumSynthesizer.render(midi: midi, sampleRate: rate, variant: variant)
        default:
            return AsmrSynthesizer.render(voice: voice, midi: midi, sampleRate: rate, variant: variant)
        }
    }

    private func renderAll(
        notes: [Int],
        variants: Int,
        dir: URL,
        label: String,
        progress: @escaping @Sendable (Double, String) -> Void,
        render: @escaping @Sendable (Int, Int) -> [Float]
    ) async throws -> [(Int, Int, [Float])] {
        let total = notes.count * variants
        let sr = Double(dir.lastPathComponent.split(separator: "-").last.flatMap { Double($0) } ?? 48_000)
        return try await withThrowingTaskGroup(of: (Int, Int, [Float]).self) { group in
            var results: [(Int, Int, [Float])] = []
            results.reserveCapacity(total)
            var done = 0
            for midi in notes {
                for variant in 0..<variants {
                    let url = dir.appendingPathComponent("n\(midi)_v\(variant).wav")
                    group.addTask(priority: .userInitiated) {
                        if let existing = try? DSP.readWAV16(url: url).samples, existing.count > 1000 {
                            return (midi, variant, existing)
                        }
                        let samples = render(midi, variant)
                        try? DSP.writeWAV16(url: url, samples: samples, sampleRate: sr)
                        return (midi, variant, samples)
                    }
                }
            }
            for try await item in group {
                results.append(item)
                done += 1
                progress(Double(done) / Double(total), "\(label) \(done) / \(total)")
            }
            return results
        }
    }

    private func store(voice: VoiceID, _ mapped: [String: RenderedNote]) {
        lock.lock()
        banks[voice.rawValue] = mapped
        if !mapped.isEmpty { ready.insert(voice.rawValue) }
        lock.unlock()
    }

    static func cacheDir(kind: String, sampleRate: Int) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base
            .appendingPathComponent("KeySax", isDirectory: true)
            .appendingPathComponent("Banks", isDirectory: true)
            .appendingPathComponent("\(cacheVersion)-\(kind)-\(sampleRate)", isDirectory: true)
    }
}
