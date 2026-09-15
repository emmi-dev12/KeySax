import Foundation

@MainActor
final class SoloPlayer {
    private var task: Task<Void, Never>?
    private(set) var isPlaying = false

    func toggle(model: AppModel) {
        if isPlaying {
            stop()
        } else {
            start(model: model)
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isPlaying = false
    }

    private func start(model: AppModel) {
        stop()
        isPlaying = true
        let notes = model.notes(for: .numbers).map(\.midi)
        task = Task { [weak model] in
            guard let model else { return }
            var cursor = notes.count / 3
            let phrases = Int.random(in: 4...7)
            for _ in 0..<phrases {
                if Task.isCancelled { break }
                let length = Int.random(in: 5...10)
                for i in 0..<length {
                    if Task.isCancelled { break }
                    if Int.random(in: 0...6) == 0 {
                        try? await Task.sleep(nanoseconds: 140_000_000)
                        continue
                    }
                    let leap = [-2, -1, -1, 0, 1, 1, 2, 3].randomElement() ?? 1
                    cursor = (cursor + leap + notes.count * 4) % notes.count
                    let midi = notes[cursor]
                    let dur: Double
                    if i == length - 1 {
                        dur = [0.35, 0.5, 0.7].randomElement() ?? 0.4
                    } else {
                        dur = [0.12, 0.14, 0.18, 0.22, 0.28].randomElement() ?? 0.16
                    }
                    let vel = Float.random(in: 0.7...1.0)
                    model.audio.playOneShot(
                        midi: midi,
                        duration: dur * 0.92,
                        velocity: vel,
                        sendMIDI: model.settings.midiEnabled
                    )
                    try? await Task.sleep(nanoseconds: UInt64(dur * 1_000_000_000))
                }
                try? await Task.sleep(nanoseconds: 180_000_000)
            }
            await MainActor.run {
                self.isPlaying = false
                self.task = nil
            }
        }
    }
}
