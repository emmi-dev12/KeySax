import Foundation
import SwiftUI
import AppKit

struct StageGlyph: Identifiable {
    let id = UUID()
    var keyID: String
    var glyph: String
    var color: Color
    var xFrac: Double
    var born: Date
    var ended: Date?
}

@MainActor
@Observable
final class AppModel {
    var settings: AppSettings
    let audio = SaxAudioEngine()
    let keyboard = KeyboardMonitor()
    let solo = SoloPlayer()

    var pressed: [KeyboardRow: Set<Int>] = [
        .numbers: [], .qwerty: [], .home: [], .bottom: []
    ]
    var loadingVoice: Set<VoiceID> = []
    var spacePressed = false
    var spectrum: [Float] = Array(repeating: 0, count: 24)
    var level: Float = 0
    var isPreparing = true
    var prepareProgress: Double = 0
    var prepareStatus = "Warming the reed…"
    var showHelp = false
    var showSettings = false
    var remappingIndex: Int? = nil
    var isRecording = false
    var recordElapsed: TimeInterval = 0
    var isRenderingVideo = false
    var videoProgress: Double = 0
    var letterHits: [LetterHit] = []
    var stageLetters: [StageGlyph] = []
    var liveSentence: String = ""
    var pendingTake: PendingTake?
    var showExportSheet = false
    var statusLine: String = "Press 1–0 to play"
    let letterCapture = LiveLetterCapture()

    private var recordTimer: Timer?
    private var persistTask: Task<Void, Never>?
    private var prepareTask: Task<Void, Never>?
    private var lastBankKey: String = ""
    private var started = false
    private var terminateObserver: NSObjectProtocol?

    init() {
        settings = AppSettings()
        audio.setVolume(settings.volume)
        audio.midi.enabled = settings.midiEnabled
        audio.midi.select(index: settings.midiDestination)
        audio.setMetersCallback { [weak self] bins, rms in
            Task { @MainActor in
                self?.spectrum = bins
                self?.level = rms
            }
        }
    }

    func notes(for row: KeyboardRow) -> [PlayableKey] {
        let voice = settings.voice(for: row)
        let codes = PhysicalKeyboard.codes(for: row)
        if voice == .drums {
            return codes.indices.map { index in
                PlayableKey(
                    index: index,
                    label: PhysicalKeyboard.glyph(forKeyCode: codes[index]),
                    midi: 36 + index,
                    caption: DrumSynthesizer.names[index % DrumSynthesizer.names.count]
                )
            }
        }
        let midis = KeyboardLayout.notes(
            scale: settings.scale,
            root: settings.root,
            octave: settings.octave(for: row),
            transpose: settings.transpose(for: row) + voice.register,
            count: codes.count
        )
        return zip(codes.indices, midis).map { index, midi in
            PlayableKey(
                index: index,
                label: PhysicalKeyboard.glyph(forKeyCode: codes[index]),
                midi: midi
            )
        }
    }

    func start() {
        if started { return }
        started = true
        keyboard.isTypingField = { TypingFocus.isTextInput() }
        keyboard.onDown = { [weak self] token, event in
            self?.handleDown(token: token, event: event) ?? false
        }
        keyboard.onUp = { [weak self] token, event in
            self?.handleUp(token: token, event: event) ?? false
        }
        keyboard.start()
        terminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.shutdown()
            }
        }
        reloadBank()
    }

    func shutdown() {
        keyboard.stop()
        solo.stop()
        audio.allNotesOff(sendMIDI: true)
        audio.stopEngine()
        settings.persist()
    }

    func reloadBank() {
        var voices = KeyboardRow.allCases.map { settings.voice(for: $0) }
        voices.append(.thump)
        lastBankKey = voices.map(\.rawValue).joined(separator: ",")
        isPreparing = true
        prepareProgress = 0
        prepareStatus = "Voicing…"
        let engine = settings.engine
        prepareTask?.cancel()
        prepareTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.audio.prepareVoices(voices, engine: engine) { progress, status in
                    Task { @MainActor in
                        self.prepareProgress = progress
                        self.prepareStatus = status
                    }
                }
                if !Task.isCancelled {
                    self.isPreparing = false
                    self.statusLine = "Four rows · \(self.settings.scale.title)"
                    self.audio.setVolume(self.settings.volume)
                }
            } catch {
                self.prepareStatus = "Couldn’t voice the rows: \(error.localizedDescription)"
            }
        }
    }

    func setRow(_ row: KeyboardRow, voice: VoiceID) {
        settings.setVoice(voice, for: row)
        flash("\(row.hint): \(voice.title)")
        guard !audio.isReady(voice) else { return }
        loadingVoice.insert(voice)
        let engine = settings.engine
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.audio.prepareVoices([voice], engine: engine) { _, status in
                    Task { @MainActor in
                        self.prepareStatus = status
                    }
                }
            } catch {
                self.flash("Couldn’t load \(voice.title)")
            }
            self.loadingVoice.remove(voice)
        }
    }

    func handleDown(token: String, event: NSEvent) -> Bool {
        if let remappingIndex {
            if token == "escape" {
                self.remappingIndex = nil
                return true
            }
            if token.count == 1 || ["tab", "space"].contains(token) {
                var map = settings.keyMap
                if remappingIndex < map.noteKeys.count {
                    map.noteKeys[remappingIndex] = token
                    settings.keyMap = map
                    settings.persist()
                }
                self.remappingIndex = nil
                return true
            }
        }

        if token == settings.keyMap.panic || token == "escape" {
            panic()
            return true
        }
        if token == "backspace" {
            backspaceLetter()
            return true
        }
        if token == "delete" {
            clearLetters()
            return true
        }
        if token == "?" {
            showHelp.toggle()
            return true
        }
        if token == settings.keyMap.octaveDown {
            settings.bumpOctave(-1)
            flash("Octave \(settings.octave)")
            return true
        }
        if token == settings.keyMap.octaveUp {
            settings.bumpOctave(1)
            flash("Octave \(settings.octave)")
            return true
        }
        if token == settings.keyMap.sustain {
            toggleSustain()
            return true
        }

        if token == "space" {
            playSpace()
            return true
        }
        if let located = PhysicalKeyboard.lookup[event.keyCode] {
            play(row: located.0, index: located.1, shift: event.modifierFlags.contains(.shift))
            return true
        }
        return false
    }

    func handleUp(token: String, event: NSEvent) -> Bool {
        if token == "space" {
            releaseSpace()
            return true
        }
        if let located = PhysicalKeyboard.lookup[event.keyCode] {
            release(row: located.0, index: located.1)
            return true
        }
        return false
    }

    var spaceMIDI: Int {
        let pc = ((settings.root.rawValue + settings.transpose) % 12 + 12) % 12
        return 24 + pc
    }

    func playSpace() {
        guard audio.isReady(.thump) else { return }
        spacePressed = true
        audio.noteOn(
            keyID: "space",
            midiNote: spaceMIDI,
            patch: .thump,
            velocity: 1,
            sendMIDI: settings.midiEnabled
        )
        logLetter(keyID: "space", glyph: " ", voice: .thump)
    }

    func releaseSpace() {
        spacePressed = false
        audio.noteOff(keyID: "space", sustain: settings.sustain, sendMIDI: settings.midiEnabled)
        endLetter(keyID: "space")
    }

    func play(row: KeyboardRow, index: Int, shift: Bool = false) {
        let patch = settings.voice(for: row)
        guard audio.isReady(patch) else { return }
        let keys = notes(for: row)
        guard keys.indices.contains(index) else { return }
        pressed[row, default: []].insert(index)
        let keyID = "\(row.rawValue)-\(index)"
        audio.noteOn(
            keyID: keyID,
            midiNote: keys[index].midi,
            patch: patch,
            sendMIDI: settings.midiEnabled
        )
        let code = PhysicalKeyboard.codes(for: row)[index]
        let typed = PhysicalKeyboard.typedGlyph(forKeyCode: code, shift: shift)
        logLetter(keyID: keyID, glyph: typed, voice: patch)
    }

    func release(row: KeyboardRow, index: Int) {
        pressed[row, default: []].remove(index)
        let keyID = "\(row.rawValue)-\(index)"
        audio.noteOff(
            keyID: keyID,
            sustain: settings.sustain,
            sendMIDI: settings.midiEnabled
        )
        endLetter(keyID: keyID)
    }

    private func logLetter(keyID: String, glyph: String, voice: VoiceID) {
        let c = NSColor(voice.accent).usingColorSpace(.sRGB) ?? .white
        let xFrac = LetterVideo.lane(for: keyID, salt: stageLetters.count)
        pruneStage()
        stageLetters.append(
            StageGlyph(
                keyID: keyID,
                glyph: glyph,
                color: Color(red: c.redComponent, green: c.greenComponent, blue: c.blueComponent),
                xFrac: xFrac,
                born: Date()
            )
        )
        liveSentence += glyph
        guard isRecording, settings.letterVideo else { return }
        let hit = LetterHit(
            keyID: keyID,
            time: letterCapture.elapsed,
            end: nil,
            glyph: glyph,
            red: c.redComponent,
            green: c.greenComponent,
            blue: c.blueComponent,
            xFrac: xFrac
        )
        letterHits.append(hit)
        letterCapture.add(hit)
    }

    private func endLetter(keyID: String) {
        if let i = stageLetters.lastIndex(where: { $0.keyID == keyID && $0.ended == nil }) {
            stageLetters[i].ended = Date()
        }
        pruneStage()
        guard isRecording, settings.letterVideo else { return }
        let t = letterCapture.elapsed
        if let i = letterHits.lastIndex(where: { $0.keyID == keyID && $0.end == nil }) {
            letterHits[i].end = t
        }
        letterCapture.end(keyID: keyID, at: t)
    }

    private func pruneStage() {
        let now = Date()
        stageLetters.removeAll { glyph in
            if let ended = glyph.ended { return now.timeIntervalSince(ended) > 1.2 }
            return now.timeIntervalSince(glyph.born) > 10
        }
        if !isRecording, liveSentence.count > 96 {
            liveSentence = String(liveSentence.suffix(80))
        }
    }

    func toggleSustain() {
        settings.sustain.toggle()
        settings.persist()
        if !settings.sustain {
            audio.releasePedal(sendMIDI: settings.midiEnabled)
        }
        flash(settings.sustain ? "Sustain on" : "Sustain off")
    }

    func panic() {
        for row in KeyboardRow.allCases { pressed[row] = [] }
        spacePressed = false
        audio.allNotesOff(sendMIDI: true)
        flash("All notes off")
    }

    func clearLetters() {
        stageLetters = []
        liveSentence = ""
        if isRecording {
            letterHits = []
            letterCapture.clearHits()
        }
        flash("Cleared")
    }

    func backspaceLetter() {
        guard !liveSentence.isEmpty else { return }
        if let last = stageLetters.popLast() {
            if liveSentence.hasSuffix(last.glyph) {
                liveSentence.removeLast(last.glyph.count)
            } else if !liveSentence.isEmpty {
                liveSentence.removeLast()
            }
        } else {
            liveSentence.removeLast()
        }
        if isRecording, !letterHits.isEmpty {
            letterHits.removeLast()
            letterCapture.removeLastHit()
        }
    }

    func setPreset(_ preset: SaxPreset) {
        setRow(.numbers, voice: VoiceID(rawValue: preset.id) ?? .alto)
    }

    func setEngine(_ engine: ToneEngine) {
        guard settings.engine != engine else { return }
        panic()
        settings.engine = engine
        settings.persist()
        reloadBank()
    }

    func setVolume(_ value: Double) {
        settings.volume = value
        audio.setVolume(value)
        schedulePersist()
    }

    func toggleRecord() {
        if isRecording {
            let wav = audio.recorder.stop()
            isRecording = false
            recordTimer?.invalidate()
            let hits = letterHits
            let elapsed = max(recordElapsed, letterCapture.elapsed)
            flash("Finishing clip…")
            Task {
                let video = settings.letterVideo ? await letterCapture.stop(extraHold: 1.2) : nil
                if let wav {
                    let end = hits.last.map { max($0.end ?? $0.time, $0.time) + 0.45 } ?? elapsed
                    pendingTake = PendingTake(
                        wav: wav,
                        video: video,
                        hits: hits,
                        duration: max(elapsed, end, 0.6),
                        sentence: hits.map(\.glyph).joined()
                    )
                    showExportSheet = true
                    flash(video == nil ? "Choose an export" : "Clip is ready")
                }
            }
        } else {
            do {
                liveSentence = ""
                stageLetters = []
                letterHits = []
                if settings.letterVideo {
                    do {
                        try letterCapture.start()
                    } catch {
                        flash("Video capture failed — audio still recording")
                    }
                }
                try audio.recorder.start()
                isRecording = true
                recordElapsed = 0
                recordTimer?.invalidate()
                recordTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                    Task { @MainActor in
                        self?.recordElapsed = self?.audio.recorder.elapsed ?? 0
                    }
                }
                flash(settings.letterVideo ? "Recording — letters drop, sentence forms" : "Recording")
            } catch {
                Task { _ = await letterCapture.stop(extraHold: 0) }
                flash("Couldn’t start recording")
            }
        }
    }

    func exportTake(_ kind: ExportKind) {
        guard let take = pendingTake else { return }
        showExportSheet = false
        if kind == .audioOnly {
            Recorder.savePanel(starting: take.wav)
            flash("Save audio")
            return
        }
        if let video = take.video, !kind.wantsAudio {
            LetterVideo.savePanel(starting: video)
            flash("Save video")
            return
        }
        isRenderingVideo = true
        videoProgress = kind.wantsAudio && take.video != nil ? 0.7 : 0
        flash(take.video != nil ? "Muxing audio…" : "Exporting \(kind.title.lowercased())…")
        Task {
            do {
                let url: URL
                if let video = take.video, kind.wantsAudio {
                    let mixed = FileManager.default.temporaryDirectory
                        .appendingPathComponent("KeySax-letterclip-\(UUID().uuidString).mp4")
                    try await LetterVideo.mux(video: video, audio: take.wav, dest: mixed)
                    url = mixed
                } else {
                    url = try await LetterVideo.render(
                        hits: take.hits,
                        audioURL: take.wav,
                        duration: take.duration,
                        sentence: take.sentence,
                        kind: kind
                    ) { p in
                        Task { @MainActor in self.videoProgress = p }
                    }
                }
                await MainActor.run {
                    self.isRenderingVideo = false
                    LetterVideo.savePanel(starting: url)
                    self.flash("Export ready")
                }
            } catch {
                await MainActor.run {
                    self.isRenderingVideo = false
                    if let video = take.video {
                        LetterVideo.savePanel(starting: video)
                        self.flash("Audio mux failed — save the silent clip")
                    } else {
                        Recorder.savePanel(starting: take.wav)
                        self.flash("Video failed — saved WAV")
                    }
                }
            }
        }
    }

    func toggleSolo() {
        solo.toggle(model: self)
        flash(solo.isPlaying ? "Random solo" : "Solo stopped")
    }

    func toggleMIDI() {
        settings.midiEnabled.toggle()
        audio.midi.enabled = settings.midiEnabled
        if settings.midiEnabled { audio.midi.refresh() }
        settings.persist()
        flash(settings.midiEnabled ? "MIDI out on" : "MIDI out off")
    }

    private func flash(_ text: String) {
        statusLine = text
    }

    private func schedulePersist() {
        persistTask?.cancel()
        persistTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            settings.persist()
        }
    }
}
