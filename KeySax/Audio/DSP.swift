import Foundation
import AVFoundation

enum DSP {
    static let sineTableSize = 4096
    static let sineTable: [Float] = {
        (0..<sineTableSize).map { i in
            sin(2.0 * Float.pi * Float(i) / Float(sineTableSize))
        }
    }()

    @inline(__always)
    static func sine(_ phase: Float) -> Float {
        let wrapped = phase - floor(phase)
        let x = wrapped * Float(sineTableSize)
        let i = Int(x) & (sineTableSize - 1)
        let f = x - floor(x)
        let a = sineTable[i]
        let b = sineTable[(i + 1) & (sineTableSize - 1)]
        return a + (b - a) * f
    }

    static func midiToHz(_ midi: Int) -> Float {
        Float(440.0 * pow(2.0, (Double(midi) - 69.0) / 12.0))
    }

    static func centsToRatio(_ cents: Float) -> Float {
        pow(2.0, cents / 1200.0)
    }

    static func adsr(
        n: Int,
        sampleRate: Float,
        attack: Float,
        decay: Float,
        sustain: Float,
        release: Float,
        hold: Float
    ) -> Float {
        let t = Float(n) / sampleRate
        if t < attack {
            let x = t / max(attack, 1e-4)
            return x * x * (3 - 2 * x)
        }
        let afterAttack = t - attack
        if afterAttack < decay {
            let x = afterAttack / max(decay, 1e-4)
            return 1.0 + (sustain - 1.0) * x
        }
        let afterDecay = afterAttack - decay
        if afterDecay < hold {
            return sustain
        }
        let relT = afterDecay - hold
        if relT >= release { return 0 }
        let x = relT / max(release, 1e-4)
        return sustain * (1 - x) * (1 - x)
    }

    struct Biquad {
        var b0: Float = 1, b1: Float = 0, b2: Float = 0
        var a1: Float = 0, a2: Float = 0
        var z1: Float = 0, z2: Float = 0

        mutating func process(_ x: Float) -> Float {
            let y = b0 * x + z1
            z1 = b1 * x - a1 * y + z2
            z2 = b2 * x - a2 * y
            return y
        }

        static func bandpass(freq: Float, q: Float, sampleRate: Float) -> Biquad {
            let w0 = 2 * Float.pi * freq / sampleRate
            let alpha = sin(w0) / (2 * max(q, 0.1))
            let cosw = cos(w0)
            let a0 = 1 + alpha
            return Biquad(
                b0: alpha / a0,
                b1: 0,
                b2: -alpha / a0,
                a1: -2 * cosw / a0,
                a2: (1 - alpha) / a0
            )
        }

        static func lowpass(freq: Float, q: Float, sampleRate: Float) -> Biquad {
            let w0 = 2 * Float.pi * min(freq, sampleRate * 0.45) / sampleRate
            let alpha = sin(w0) / (2 * max(q, 0.1))
            let cosw = cos(w0)
            let a0 = 1 + alpha
            return Biquad(
                b0: (1 - cosw) * 0.5 / a0,
                b1: (1 - cosw) / a0,
                b2: (1 - cosw) * 0.5 / a0,
                a1: -2 * cosw / a0,
                a2: (1 - alpha) / a0
            )
        }

        static func highpass(freq: Float, q: Float, sampleRate: Float) -> Biquad {
            let w0 = 2 * Float.pi * freq / sampleRate
            let alpha = sin(w0) / (2 * max(q, 0.1))
            let cosw = cos(w0)
            let a0 = 1 + alpha
            return Biquad(
                b0: (1 + cosw) * 0.5 / a0,
                b1: -(1 + cosw) / a0,
                b2: (1 + cosw) * 0.5 / a0,
                a1: -2 * cosw / a0,
                a2: (1 - alpha) / a0
            )
        }

        static func peaking(freq: Float, q: Float, gainDB: Float, sampleRate: Float) -> Biquad {
            let A = pow(10 as Float, gainDB / 40)
            let w0 = 2 * Float.pi * min(freq, sampleRate * 0.45) / sampleRate
            let alpha = sin(w0) / (2 * max(q, 0.1))
            let cosw = cos(w0)
            let a0 = 1 + alpha / A
            return Biquad(
                b0: (1 + alpha * A) / a0,
                b1: -2 * cosw / a0,
                b2: (1 - alpha * A) / a0,
                a1: -2 * cosw / a0,
                a2: (1 - alpha / A) / a0
            )
        }

        static func highshelf(freq: Float, gainDB: Float, sampleRate: Float) -> Biquad {
            let A = pow(10 as Float, gainDB / 40)
            let w0 = 2 * Float.pi * min(freq, sampleRate * 0.45) / sampleRate
            let cosw = cos(w0)
            let alpha = sin(w0) / 2 * sqrt((A + 1 / A) * 0.8 + 2)
            let a0 = (A + 1) - (A - 1) * cosw + 2 * sqrt(A) * alpha
            return Biquad(
                b0: A * ((A + 1) + (A - 1) * cosw + 2 * sqrt(A) * alpha) / a0,
                b1: -2 * A * ((A - 1) + (A + 1) * cosw) / a0,
                b2: A * ((A + 1) + (A - 1) * cosw - 2 * sqrt(A) * alpha) / a0,
                a1: 2 * ((A - 1) - (A + 1) * cosw) / a0,
                a2: ((A + 1) - (A - 1) * cosw - 2 * sqrt(A) * alpha) / a0
            )
        }
    }

    struct OnePole {
        var z: Float = 0
        mutating func lowpass(_ x: Float, cutoff: Float) -> Float {
            let c = min(0.99, max(0.0005, cutoff))
            z += c * (x - z)
            return z
        }
    }

    struct FracDelay {
        var buf: [Float]
        var w: Int = 0

        init(maxLength: Int) {
            buf = [Float](repeating: 0, count: max(32, maxLength))
        }

        mutating func read(_ delay: Float) -> Float {
            let n = buf.count
            var r = Float(w) - max(1, delay)
            while r < 0 { r += Float(n) }
            let i0 = Int(r) % n
            let i1 = (i0 + 1) % n
            let f = r - floor(r)
            return buf[i0] * (1 - f) + buf[i1] * f
        }

        mutating func write(_ input: Float) {
            buf[w] = input
            w += 1
            if w >= buf.count { w = 0 }
        }
    }

    static func reedShape(_ x: Float, drive: Float, even: Float) -> Float {
        let d = max(-8, min(8, x * drive))
        return tanhApprox(d + even * d * abs(d))
    }

    static func tanhApprox(_ x: Float) -> Float {
        let x2 = x * x
        return x * (27 + x2) / (27 + 9 * x2)
    }

    static func normalize(_ samples: inout [Float], peak: Float) {
        var maxAbs: Float = 0
        for s in samples {
            let a = abs(s)
            if a > maxAbs { maxAbs = a }
        }
        guard maxAbs > 1e-6 else { return }
        let g = peak / maxAbs
        for i in samples.indices { samples[i] *= g }
    }

    static func applyFade(_ samples: inout [Float], sampleRate: Float, fadeIn: Float, fadeOut: Float) {
        let fi = max(1, Int(fadeIn * sampleRate))
        let fo = max(1, Int(fadeOut * sampleRate))
        let n = samples.count
        for i in 0..<min(fi, n) {
            let x = Float(i) / Float(fi)
            samples[i] *= x * x * (3 - 2 * x)
        }
        for i in 0..<min(fo, n) {
            let x = Float(i) / Float(fo)
            samples[n - 1 - i] *= x * x * (3 - 2 * x)
        }
    }

    static func makePCMBuffer(mono: [Float], format: AVAudioFormat, stereoSpread: Float = 0.12) -> AVAudioPCMBuffer? {
        let frames = AVAudioFrameCount(mono.count)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return nil }
        buffer.frameLength = frames
        let channels = Int(format.channelCount)
        if format.commonFormat == .pcmFormatFloat32, let chans = buffer.floatChannelData {
            for i in 0..<mono.count {
                let s = mono[i]
                chans[0][i] = s
                if channels > 1 {
                    let j = max(0, i - 1)
                    chans[1][i] = s * (1 - stereoSpread) + mono[j] * stereoSpread
                }
            }
        } else if format.commonFormat == .pcmFormatInt16, let chans = buffer.int16ChannelData {
            for i in 0..<mono.count {
                let clipped = max(-1, min(1, mono[i]))
                let v = Int16(clipped * 32767)
                chans[0][i] = v
                if channels > 1 { chans[1][i] = v }
            }
        }
        return buffer
    }

    static func writeWAV16(url: URL, samples: [Float], sampleRate: Double) throws {
        var pcm = [Int16](repeating: 0, count: samples.count)
        for i in samples.indices {
            let clipped = max(-1, min(1, samples[i]))
            pcm[i] = Int16((clipped * 32767).rounded())
        }
        let dataSize = UInt32(pcm.count * 2)
        var header = Data()
        func append(_ s: String) { header.append(contentsOf: s.utf8) }
        func appendU32(_ v: UInt32) {
            var le = v.littleEndian
            header.append(Data(bytes: &le, count: 4))
        }
        func appendU16(_ v: UInt16) {
            var le = v.littleEndian
            header.append(Data(bytes: &le, count: 2))
        }
        append("RIFF")
        appendU32(36 + dataSize)
        append("WAVE")
        append("fmt ")
        appendU32(16)
        appendU16(1)
        appendU16(1)
        appendU32(UInt32(sampleRate))
        appendU32(UInt32(sampleRate) * 2)
        appendU16(2)
        appendU16(16)
        append("data")
        appendU32(dataSize)
        var file = header
        pcm.withUnsafeBytes { file.append(contentsOf: $0) }
        try file.write(to: url, options: .atomic)
    }

    static func readWAV16(url: URL) throws -> (samples: [Float], sampleRate: Double) {
        let data = try Data(contentsOf: url)
        guard data.count > 44 else { throw CocoaError(.fileReadCorruptFile) }
        let sampleRate = Double(data.u32(at: 24))
        let bits = Int(data.u16(at: 34))
        let channels = Int(data.u16(at: 22))
        let dataStart = 44
        let payload = data.dropFirst(dataStart)
        let strideN = max(1, channels) * (bits / 8)
        let count = payload.count / strideN
        var samples = [Float](repeating: 0, count: count)
        payload.withUnsafeBytes { raw in
            if bits == 16 {
                let ints = raw.bindMemory(to: Int16.self)
                for i in 0..<count {
                    samples[i] = Float(ints[i * channels]) / 32768.0
                }
            }
        }
        return (samples, sampleRate)
    }
}

private extension Data {
    func u16(at offset: Int) -> UInt16 {
        UInt16(self[offset]) | UInt16(self[offset + 1]) << 8
    }

    func u32(at offset: Int) -> UInt32 {
        UInt32(self[offset])
            | UInt32(self[offset + 1]) << 8
            | UInt32(self[offset + 2]) << 16
            | UInt32(self[offset + 3]) << 24
    }
}

struct SplitNote {
    var attack: [Float]
    var loop: [Float]
}

enum LoopSplitter {
    /// Long interior loop, matching the web player: hold the body of the
    /// note instead of a short vibrato-cycle splice.
    static func split(
        samples: [Float],
        sampleRate: Float,
        attackTime: Float,
        tailPad: Float = 0.06,
        loopCycles: Int = 0,
        vibratoRate: Float = 5
    ) -> SplitNote {
        let n = samples.count
        let attackEnd = min(n - 256, max(64, Int(attackTime * sampleRate)))
        var loopStart = attackEnd
        let search = min(400, n - attackEnd - 8)
        for i in 0..<search {
            let idx = attackEnd + i
            if idx + 1 < n, samples[idx] >= 0, samples[idx + 1] < 0 {
                loopStart = idx + 1
                break
            }
        }
        let tail = max(loopStart + 128, n - max(8, Int(tailPad * sampleRate)))
        let loopEnd = min(n, tail)
        guard loopEnd > loopStart + 64 else {
            return SplitNote(attack: samples, loop: Array(samples.suffix(min(128, n))))
        }
        var loop = Array(samples[loopStart..<loopEnd])
        crossfadeLoop(&loop, fade: min(512, loop.count / 10))
        let attack = Array(samples[0..<loopStart])
        _ = loopCycles
        _ = vibratoRate
        return SplitNote(attack: attack, loop: loop)
    }

    static func crossfadeLoop(_ loop: inout [Float], fade: Int) {
        guard loop.count > fade * 2, fade > 0 else { return }
        for i in 0..<fade {
            let w = Float(i) / Float(fade)
            let a = loop[i]
            let b = loop[loop.count - fade + i]
            loop[i] = a * w + b * (1 - w)
        }
    }
}
