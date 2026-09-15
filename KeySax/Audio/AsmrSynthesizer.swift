import Foundation

enum AsmrSynthesizer {
    static func render(voice: VoiceID, midi: Int, sampleRate: Float, variant: Int) -> [Float] {
        switch voice {
        case .kalimba: return kalimba(midi: midi, sampleRate: sampleRate, variant: variant)
        case .glass: return glass(midi: midi, sampleRate: sampleRate, variant: variant)
        case .rhodes: return rhodes(midi: midi, sampleRate: sampleRate, variant: variant)
        case .chimes: return chimes(midi: midi, sampleRate: sampleRate, variant: variant)
        case .musicBox: return musicBox(midi: midi, sampleRate: sampleRate, variant: variant)
        case .pad: return pad(midi: midi, sampleRate: sampleRate, variant: variant)
        case .thump: return thump(midi: midi, sampleRate: sampleRate, variant: variant)
        default:
            return PianoSynthesizer.render(midi: midi, sampleRate: sampleRate, variant: variant)
        }
    }

    private static func rng(_ midi: Int, _ variant: Int, _ salt: UInt64) -> () -> Float {
        var state = UInt64(midi &* 4_873 &+ variant &* 1_109 &+ Int(salt & 0xFFFF))
        return {
            state = state &* 6_364_136_223_846_793_005 &+ 1
            return Float(Double((state >> 33) & 0xFFFFFFFF) / Double(UInt32.max))
        }
    }

    /// Thumb piano — close, woody metal, long sweet decay.
    private static func kalimba(midi: Int, sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(midi, variant, 11)
        let f0 = DSP.midiToHz(midi)
        let dur: Float = 3.1
        let nSamples = Int(dur * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        let ratios: [(Float, Float, Float)] = [
            (1.000, 1.00, 1.6),
            (2.012, 0.22, 3.4),
            (2.758, 0.16, 4.8),
            (4.072, 0.08, 7.0)
        ]
        var phases = ratios.map { _ in next() }
        var nail = DSP.Biquad.highpass(freq: 2_400, q: 0.7, sampleRate: sampleRate)
        var wood = DSP.Biquad.peaking(freq: 420, q: 2.8, gainDB: 3.0, sampleRate: sampleRate)
        var dc = DSP.Biquad.highpass(freq: 40, q: 0.7, sampleRate: sampleRate)
        for n in 0..<nSamples {
            let t = Float(n) * inv
            var s: Float = 0
            for (i, r) in ratios.enumerated() {
                phases[i] += f0 * r.0 * inv
                if phases[i] > 1 { phases[i] -= floor(phases[i]) }
                s += r.1 * DSP.sine(phases[i]) * exp(-t * r.2)
            }
            let click = nail.process(next() * 2 - 1) * 0.12 * exp(-t / 0.008)
            var y = (s + click) * min(1, t / 0.003)
            y = wood.process(y)
            y = dc.process(y)
            out[n] = y
        }
        DSP.normalize(&out, peak: 0.30)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0008, fadeOut: 0.08)
        return out
    }

    /// Finger on a glass rim — beating sines, lots of air.
    private static func glass(midi: Int, sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(midi, variant, 23)
        let f0 = DSP.midiToHz(midi)
        let dur: Float = 4.2
        let nSamples = Int(dur * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        let beat = 0.7 + next() * 0.5
        var p1 = next(), p2 = next(), p3 = next()
        var air = DSP.Biquad.bandpass(freq: 5_200, q: 0.6, sampleRate: sampleRate)
        var dc = DSP.Biquad.highpass(freq: 40, q: 0.7, sampleRate: sampleRate)
        for n in 0..<nSamples {
            let t = Float(n) * inv
            p1 += f0 * inv
            p2 += (f0 + beat) * inv
            p3 += f0 * 2.003 * inv
            if p1 > 1 { p1 -= floor(p1) }
            if p2 > 1 { p2 -= floor(p2) }
            if p3 > 1 { p3 -= floor(p3) }
            let env = min(1, t / 0.06) * exp(-t / 2.4)
            let s = (DSP.sine(p1) + DSP.sine(p2)) * 0.46 + DSP.sine(p3) * 0.07
            let hiss = air.process(next() * 2 - 1) * 0.03 * env
            out[n] = dc.process((s + hiss) * env)
        }
        DSP.normalize(&out, peak: 0.26)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.02, fadeOut: 0.12)
        return out
    }

    /// Close-mic electric piano tine.
    private static func rhodes(midi: Int, sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(midi, variant, 37)
        let f0 = DSP.midiToHz(midi)
        let dur: Float = 2.8
        let nSamples = Int(dur * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        var p0 = next(), p1 = next(), p2 = next()
        var bell = DSP.Biquad.bandpass(freq: 4_800, q: 0.9, sampleRate: sampleRate)
        var body = DSP.Biquad.peaking(freq: 280, q: 1.2, gainDB: 2.5, sampleRate: sampleRate)
        var dc = DSP.Biquad.highpass(freq: 40, q: 0.7, sampleRate: sampleRate)
        for n in 0..<nSamples {
            let t = Float(n) * inv
            p0 += f0 * inv
            p1 += f0 * 2.0008 * inv
            p2 += f0 * 4.02 * inv
            if p0 > 1 { p0 -= floor(p0) }
            if p1 > 1 { p1 -= floor(p1) }
            if p2 > 1 { p2 -= floor(p2) }
            let tine = DSP.sine(p0) * exp(-t / 1.15)
                + 0.28 * DSP.sine(p1) * exp(-t / 0.55)
                + 0.07 * DSP.sine(p2) * exp(-t / 0.22)
            let ham = bell.process(next() * 2 - 1) * 0.18 * exp(-t / 0.01)
            var y = (tine + ham) * min(1, t / 0.002)
            y = body.process(y)
            y = DSP.tanhApprox(y * 1.15)
            out[n] = dc.process(y)
        }
        DSP.normalize(&out, peak: 0.30)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0006, fadeOut: 0.06)
        return out
    }

    /// Wind-bar chimes, inharmonic and sparkly.
    private static func chimes(midi: Int, sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(midi, variant, 53)
        let f0 = DSP.midiToHz(midi)
        let dur: Float = 4.4
        let nSamples = Int(dur * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        let ratios: [(Float, Float, Float)] = [
            (1.000, 1.00, 0.9),
            (2.758, 0.55, 1.3),
            (5.404, 0.28, 1.8),
            (8.933, 0.12, 2.6)
        ]
        var phases = ratios.map { _ in next() }
        var air = DSP.Biquad.highpass(freq: 3_000, q: 0.6, sampleRate: sampleRate)
        var dc = DSP.Biquad.highpass(freq: 50, q: 0.7, sampleRate: sampleRate)
        for n in 0..<nSamples {
            let t = Float(n) * inv
            var s: Float = 0
            for (i, r) in ratios.enumerated() {
                let fh = f0 * r.0
                if fh > sampleRate * 0.45 { continue }
                phases[i] += fh * inv
                if phases[i] > 1 { phases[i] -= floor(phases[i]) }
                s += r.1 * DSP.sine(phases[i]) * exp(-t * r.2)
            }
            let sparkle = air.process(next() * 2 - 1) * 0.04 * exp(-t / 0.04)
            out[n] = dc.process((s + sparkle) * min(1, t / 0.002))
        }
        DSP.normalize(&out, peak: 0.24)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.001, fadeOut: 0.15)
        return out
    }

    private static func musicBox(midi: Int, sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(midi, variant, 71)
        let f0 = DSP.midiToHz(midi)
        let dur: Float = 1.5
        let nSamples = Int(dur * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        var phases = (0..<6).map { _ in next() }
        var tick = DSP.Biquad.highpass(freq: 5_000, q: 0.8, sampleRate: sampleRate)
        var dc = DSP.Biquad.highpass(freq: 60, q: 0.7, sampleRate: sampleRate)
        for n in 0..<nSamples {
            let t = Float(n) * inv
            var s: Float = 0
            for h in 1...6 {
                phases[h - 1] += f0 * Float(h) * (1 + 0.0004 * Float(h * h)) * inv
                if phases[h - 1] > 1 { phases[h - 1] -= floor(phases[h - 1]) }
                s += (1 / pow(Float(h), 1.35)) * DSP.sine(phases[h - 1]) * exp(-t * (2.2 + Float(h) * 0.8))
            }
            let pin = tick.process(next() * 2 - 1) * 0.1 * exp(-t / 0.006)
            out[n] = dc.process((s + pin) * min(1, t / 0.0015))
        }
        DSP.normalize(&out, peak: 0.28)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0004, fadeOut: 0.05)
        return out
    }

    /// Slow, breathy pad — loopable.
    private static func pad(midi: Int, sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(midi, variant, 97)
        let f0 = DSP.midiToHz(midi)
        let dur: Float = 2.4
        let nSamples = Int(dur * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        let detune: [Float] = [-7, -2.5, 0, 3.1, 8]
        var phases = detune.map { _ in next() }
        var air = DSP.Biquad.bandpass(freq: 2_400, q: 0.7, sampleRate: sampleRate)
        var lp = DSP.OnePole()
        var dc = DSP.Biquad.highpass(freq: 40, q: 0.7, sampleRate: sampleRate)
        for n in 0..<nSamples {
            var s: Float = 0
            for (i, cents) in detune.enumerated() {
                let f = f0 * DSP.centsToRatio(cents)
                phases[i] += f * inv
                if phases[i] > 1 { phases[i] -= floor(phases[i]) }
                s += DSP.sine(phases[i])
            }
            s /= Float(detune.count)
            let env = DSP.adsr(
                n: n,
                sampleRate: sampleRate,
                attack: 0.16,
                decay: 0.2,
                sustain: 0.82,
                release: 0.08,
                hold: dur - 0.44
            )
            let hiss = air.process(next() * 2 - 1) * 0.05 * env
            var y = lp.lowpass(s, cutoff: 0.12) * env + hiss
            y = dc.process(y)
            out[n] = y
        }
        DSP.normalize(&out, peak: 0.28)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.01, fadeOut: 0.04)
        return out
    }

    /// Spacebar — 808-style chest thump, pitch drop + click.
    private static func thump(midi: Int, sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(midi, variant, 131)
        let fEnd = max(32, DSP.midiToHz(midi))
        let fStart = fEnd * (3.4 + next() * 0.5)
        let dur: Float = 0.85
        let nSamples = Int(dur * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        var phase: Float = 0
        var clickHP = DSP.Biquad.highpass(freq: 2_200, q: 0.7, sampleRate: sampleRate)
        var bodyLP = DSP.OnePole()
        for n in 0..<nSamples {
            let t = Float(n) * inv
            let drop = exp(-t / 0.038)
            let freq = fEnd + (fStart - fEnd) * drop
            phase += freq * inv
            if phase > 1 { phase -= floor(phase) }
            let body = DSP.sine(phase) * exp(-t / 0.28)
            let sub = DSP.sine(phase * 0.5) * 0.35 * exp(-t / 0.4)
            let click = clickHP.process(next() * 2 - 1) * 0.22 * exp(-t / 0.004)
            var y = body + sub + click
            y = bodyLP.lowpass(y, cutoff: 0.35 + drop * 0.25)
            out[n] = y * min(1, t / 0.001)
        }
        DSP.normalize(&out, peak: 0.42)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0003, fadeOut: 0.04)
        return out
    }
}
