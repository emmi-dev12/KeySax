import Foundation
import AVFoundation
import Accelerate
import CoreAudio

final class SaxAudioEngine: @unchecked Sendable {
    static let voiceCount = 32

    private let engine = AVAudioEngine()
    private let master = AVAudioMixerNode()
    private let recordMixer = AVAudioMixerNode()
    private var voices: [Voice] = []
    private let lock = NSLock()
    private let fadeQueue = DispatchQueue(label: "com.keysax.fade", qos: .userInteractive)

    private(set) var format: AVAudioFormat
    private var bank: SampleBank
    private var currentVolume: Float = 0.85
    private var analyzer = SpectrumAnalyzer()
    private var metersCallback: (@Sendable ([Float], Float) -> Void)?
    private var lastMeterTime: CFAbsoluteTime = 0

    var recorder: Recorder
    var midi = MIDIOutput()

    private final class Voice {
        let player = AVAudioPlayerNode()
        let fader = AVAudioMixerNode()
        var keyID: String?
        var midi: Int = -1
        var held = false
        var fading = false
        var started: UInt64 = 0
        var fadeWork: DispatchWorkItem?
        var state: State = .idle
        enum State { case idle, playing, fading }
    }

    init() {
        let hw = engine.outputNode.outputFormat(forBus: 0)
        let sr = hw.sampleRate > 0 ? hw.sampleRate : 48_000
        format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 2)
            ?? AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!
        bank = SampleBank(format: format)
        recorder = Recorder(format: format)

        engine.attach(master)
        engine.attach(recordMixer)
        do {
            try engine.connectNode(recordMixer, to: master, format: format)
            try engine.connectNode(master, to: engine.mainMixerNode, format: format)
        } catch {
            assertionFailure("KeySax audio graph failed: \(error)")
        }
        engine.mainMixerNode.outputVolume = 1

        for _ in 0..<Self.voiceCount {
            let voice = Voice()
            engine.attach(voice.player)
            engine.attach(voice.fader)
            do {
                try engine.connectNode(voice.player, to: voice.fader, format: format)
                try engine.connectNode(voice.fader, to: recordMixer, format: format)
            } catch {
                assertionFailure("KeySax voice graph failed: \(error)")
            }
            voices.append(voice)
        }

        installMeterTap()
        tuneLatency()
        engine.prepare()
    }

    func start() throws {
        if !engine.isRunning {
            try engine.start()
        }
    }

    func stopEngine() {
        if engine.isRunning { engine.stop() }
    }

    var isReady: Bool { bank.isReady }

    func isReady(_ voice: VoiceID) -> Bool { bank.isReady(voice) }

    func setVolume(_ value: Double) {
        currentVolume = Float(max(0, min(1, value)))
        master.outputVolume = currentVolume
    }

    func setMetersCallback(_ callback: @escaping @Sendable ([Float], Float) -> Void) {
        metersCallback = callback
    }

    func prepareVoices(
        _ voices: [VoiceID],
        engine tone: ToneEngine,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws {
        try await bank.ensure(voices: voices, engine: tone, progress: progress)
        try start()
    }

    func noteOn(
        keyID: String,
        midiNote: Int,
        patch: VoiceID,
        velocity: Float = 1,
        sendMIDI: Bool
    ) {
        lock.lock()
        if voices.contains(where: { $0.keyID == keyID && $0.held && !$0.fading }) {
            lock.unlock()
            return
        }
        guard let slot = allocateLocked() else {
            lock.unlock()
            return
        }
        slot.fadeWork?.cancel()
        slot.keyID = keyID
        slot.midi = midiNote
        slot.held = true
        slot.fading = false
        slot.state = .playing
        slot.started = DispatchTime.now().uptimeNanoseconds
        let jitter = 0.97 + Float.random(in: 0...0.06)
        slot.fader.outputVolume = max(0.05, min(1, velocity * jitter))
        lock.unlock()

        let variant = bank.randomVariant(for: patch)
        guard let sample = bank.note(voice: patch, midi: midiNote, variant: variant) else { return }

        slot.player.stop()
        if slot.player.engine != nil {
            slot.player.scheduleBuffer(sample.attack, at: nil, options: [], completionHandler: nil)
            if patch.loops, sample.loop.frameLength > 32 {
                slot.player.scheduleBuffer(sample.loop, at: nil, options: [.loops], completionHandler: nil)
            }
            if !slot.player.isPlaying {
                try? slot.player.playAudio()
            }
        }
        if sendMIDI {
            midi.noteOn(midi: midiNote, velocity: UInt8(max(1, min(127, velocity * 110))))
        }
    }

    func noteOff(keyID: String, sustain: Bool, sendMIDI: Bool) {
        lock.lock()
        let matching = voices.filter { $0.keyID == keyID && $0.held }
        for voice in matching {
            voice.held = false
            if !sustain {
                fadeLocked(voice)
                if sendMIDI { midi.noteOff(midi: voice.midi) }
            }
        }
        lock.unlock()
    }

    func releasePedal(sendMIDI: Bool) {
        lock.lock()
        for voice in voices where voice.state == .playing && !voice.held {
            fadeLocked(voice)
            if sendMIDI { midi.noteOff(midi: voice.midi) }
        }
        lock.unlock()
    }

    func allNotesOff(sendMIDI: Bool) {
        lock.lock()
        for voice in voices where voice.state != .idle {
            voice.held = false
            fadeLocked(voice, fast: true)
            if sendMIDI { midi.noteOff(midi: voice.midi) }
        }
        lock.unlock()
    }

    func playOneShot(midi: Int, duration: TimeInterval, velocity: Float, sendMIDI: Bool) {
        let id = "solo-\(UUID().uuidString)"
        noteOn(keyID: id, midiNote: midi, patch: .alto, velocity: velocity, sendMIDI: sendMIDI)
        fadeQueue.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.noteOff(keyID: id, sustain: false, sendMIDI: sendMIDI)
        }
    }

    private func allocateLocked() -> Voice? {
        if let idle = voices.first(where: { $0.state == .idle }) { return idle }
        if let fading = voices
            .filter({ $0.state == .fading && !$0.held })
            .min(by: { $0.started < $1.started }) {
            fading.player.stop()
            fading.fader.outputVolume = 1
            fading.fadeWork?.cancel()
            return fading
        }
        return voices.first(where: { !$0.held })
    }

    private func fadeLocked(_ voice: Voice, fast: Bool = false) {
        voice.fading = true
        voice.state = .fading
        let keyID = voice.keyID
        voice.keyID = nil
        let start = voice.fader.outputVolume
        let steps = fast ? 6 : 14
        let interval: Double = fast ? 0.008 : 0.01
        voice.fadeWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.runFade(voice: voice, start: start, steps: steps, interval: interval, originalKey: keyID)
        }
        voice.fadeWork = work
        fadeQueue.async(execute: work)
    }

    private func runFade(voice: Voice, start: Float, steps: Int, interval: Double, originalKey: String?) {
        for i in 1...steps {
            if voice.fadeWork?.isCancelled == true { return }
            let g = 1 - Float(i) / Float(steps)
            voice.fader.outputVolume = start * g * g
            Thread.sleep(forTimeInterval: interval)
        }
        lock.lock()
        if voice.state == .fading {
            voice.player.stop()
            voice.fader.outputVolume = 1
            voice.state = .idle
            voice.held = false
            voice.fading = false
            if voice.keyID == originalKey { voice.keyID = nil }
        }
        lock.unlock()
    }

    private func installMeterTap() {
        let buf: AVAudioFrameCount = 1024
        do {
            try recordMixer.installAudioTap(onBus: 0, bufferSize: buf, format: format) { [weak self] buffer, _ in
                guard let self else { return }
                let now = CFAbsoluteTimeGetCurrent()
                if now - self.lastMeterTime < 1.0 / 28.0 { return }
                self.lastMeterTime = now
                let pcm = AVAudioPCMBuffer(copying: buffer)
                let (bins, rms) = self.analyzer.analyze(pcm)
                self.recorder.append(pcm)
                self.metersCallback?(bins, rms)
            }
        } catch {
            assertionFailure("KeySax meter tap failed: \(error)")
        }
    }

    private func tuneLatency() {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &device)
        guard status == noErr else { return }

        var bufferAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyBufferFrameSize,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var frames: UInt32 = 128
        let dataSize = UInt32(MemoryLayout<UInt32>.size)
        AudioObjectSetPropertyData(device, &bufferAddr, 0, nil, dataSize, &frames)
    }
}

final class SpectrumAnalyzer: @unchecked Sendable {
    private let n = 512
    private var window: [Float]
    private var realp: [Float]
    private var imagp: [Float]
    private var magnitudes: [Float]
    private var setup: FFTSetup?

    init() {
        let size = 512
        window = (0..<size).map { i in
            0.5 - 0.5 * cos(2 * Float.pi * Float(i) / Float(size - 1))
        }
        realp = [Float](repeating: 0, count: size / 2)
        imagp = [Float](repeating: 0, count: size / 2)
        magnitudes = [Float](repeating: 0, count: size / 2)
        setup = vDSP_create_fftsetup(vDSP_Length(log2(Float(size))), FFTRadix(kFFTRadix2))
    }

    deinit {
        if let setup { vDSP_destroy_fftsetup(setup) }
    }

    func analyze(_ buffer: AVAudioPCMBuffer) -> ([Float], Float) {
        guard let data = buffer.floatChannelData else {
            return (Array(repeating: 0, count: 24), 0)
        }
        let frames = Int(buffer.frameLength)
        let take = min(n, frames)
        var input = [Float](repeating: 0, count: n)
        for i in 0..<take {
            input[i] = data[0][i] * window[i]
        }
        var rms: Float = 0
        vDSP_rmsqv(input, 1, &rms, vDSP_Length(take))

        guard let setup else { return (Array(repeating: 0, count: 24), rms) }

        realp.withUnsafeMutableBufferPointer { realBuf in
            imagp.withUnsafeMutableBufferPointer { imagBuf in
                var split = DSPSplitComplex(realp: realBuf.baseAddress!, imagp: imagBuf.baseAddress!)
                input.withUnsafeBufferPointer { src in
                    src.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: n / 2) { complex in
                        vDSP_ctoz(complex, 2, &split, 1, vDSP_Length(n / 2))
                    }
                }
                vDSP_fft_zrip(setup, &split, 1, vDSP_Length(log2(Float(n))), FFTDirection(FFT_FORWARD))
                vDSP_zvmags(&split, 1, &magnitudes, 1, vDSP_Length(n / 2))
            }
        }

        let bands = 24
        var bins = [Float](repeating: 0, count: bands)
        for b in 0..<bands {
            let start = Int(pow(Float(n / 2), Float(b) / Float(bands)))
            let end = max(start + 1, Int(pow(Float(n / 2), Float(b + 1) / Float(bands))))
            var sum: Float = 0
            let hi = min(end, magnitudes.count)
            let lo = min(start, hi)
            for i in lo..<hi { sum += magnitudes[i] }
            bins[b] = min(1, sqrt(sum / Float(max(1, hi - lo))) * 0.08)
        }
        return (bins, min(1, rms * 3.2))
    }
}
