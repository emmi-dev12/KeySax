import Foundation

enum DrumSynthesizer {
    static let names = [
        "Kick", "Snare", "Hat", "Open", "Clap",
        "Tom L", "Tom M", "Tom H", "Rim", "Crash",
        "Perc", "Shaker", "Cowbell"
    ]

    static func render(midi: Int, sampleRate: Float, variant: Int) -> [Float] {
        let piece = abs(midi - 36) % names.count
        switch piece {
        case 0: return kick(sampleRate: sampleRate, variant: variant)
        case 1: return snare(sampleRate: sampleRate, variant: variant)
        case 2: return hat(sampleRate: sampleRate, variant: variant, open: false)
        case 3: return hat(sampleRate: sampleRate, variant: variant, open: true)
        case 4: return clap(sampleRate: sampleRate, variant: variant)
        case 5: return tom(sampleRate: sampleRate, variant: variant, freq: 92)
        case 6: return tom(sampleRate: sampleRate, variant: variant, freq: 128)
        case 7: return tom(sampleRate: sampleRate, variant: variant, freq: 176)
        case 8: return rim(sampleRate: sampleRate, variant: variant)
        case 9: return crash(sampleRate: sampleRate, variant: variant)
        case 10: return perc(sampleRate: sampleRate, variant: variant)
        case 11: return shaker(sampleRate: sampleRate, variant: variant)
        default: return cowbell(sampleRate: sampleRate, variant: variant)
        }
    }

    private static func rng(_ salt: Int, _ variant: Int) -> () -> Float {
        var state = UInt64(salt &* 9_917 &+ variant &* 4_241 &+ 17)
        return {
            state = state &* 6_364_136_223_846_793_005 &+ 1
            return Float(Double((state >> 33) & 0xFFFFFFFF) / Double(UInt32.max))
        }
    }

    private static func kick(sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(3, variant)
        let nSamples = Int(0.55 * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        var phase: Float = 0
        var hp = DSP.Biquad.highpass(freq: 1800, q: 0.7, sampleRate: sampleRate)
        for n in 0..<nSamples {
            let t = Float(n) * inv
            let drop = exp(-t / 0.032)
            let freq: Float = 48 + 110 * drop
            phase += freq * inv
            if phase > 1 { phase -= floor(phase) }
            let body = DSP.sine(phase) * exp(-t / 0.22)
            let click = hp.process(next() * 2 - 1) * 0.18 * exp(-t / 0.004)
            out[n] = body + click
        }
        DSP.normalize(&out, peak: 0.46)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0002, fadeOut: 0.03)
        return out
    }

    private static func snare(sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(7, variant)
        let nSamples = Int(0.32 * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        var bp = DSP.Biquad.bandpass(freq: 180, q: 1.1, sampleRate: sampleRate)
        var noiseBP = DSP.Biquad.bandpass(freq: 6_400, q: 0.7, sampleRate: sampleRate)
        var phase: Float = 0
        for n in 0..<nSamples {
            let t = Float(n) * inv
            phase += 186 * inv
            if phase > 1 { phase -= floor(phase) }
            let tone = bp.process(DSP.sine(phase)) * exp(-t / 0.06)
            let noise = noiseBP.process(next() * 2 - 1) * 0.7 * exp(-t / 0.08)
            out[n] = tone * 0.45 + noise
        }
        DSP.normalize(&out, peak: 0.38)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0003, fadeOut: 0.02)
        return out
    }

    private static func hat(sampleRate: Float, variant: Int, open: Bool) -> [Float] {
        let next = rng(open ? 11 : 13, variant)
        let dur: Float = open ? 0.28 : 0.055
        let nSamples = Int(dur * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        var hp = DSP.Biquad.highpass(freq: open ? 5_500 : 7_200, q: 0.6, sampleRate: sampleRate)
        var bp = DSP.Biquad.bandpass(freq: 9_000, q: 0.9, sampleRate: sampleRate)
        let fall: Float = open ? 0.09 : 0.018
        for n in 0..<nSamples {
            let t = Float(n) * inv
            let nse = hp.process(bp.process(next() * 2 - 1))
            out[n] = nse * exp(-t / fall)
        }
        DSP.normalize(&out, peak: open ? 0.26 : 0.22)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0002, fadeOut: 0.01)
        return out
    }

    private static func clap(sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(17, variant)
        let nSamples = Int(0.28 * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        var bp = DSP.Biquad.bandpass(freq: 1_400, q: 0.8, sampleRate: sampleRate)
        let bursts: [Float] = [0.0, 0.012, 0.021, 0.034]
        for n in 0..<nSamples {
            let t = Float(n) * inv
            var env: Float = 0
            for b in bursts {
                if t >= b { env += exp(-(t - b) / 0.018) }
            }
            out[n] = bp.process(next() * 2 - 1) * env * 0.55
        }
        DSP.normalize(&out, peak: 0.34)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0002, fadeOut: 0.02)
        return out
    }

    private static func tom(sampleRate: Float, variant: Int, freq: Float) -> [Float] {
        let next = rng(Int(freq), variant)
        let nSamples = Int(0.42 * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        var phase: Float = 0
        var noiseHP = DSP.Biquad.highpass(freq: 1_200, q: 0.7, sampleRate: sampleRate)
        for n in 0..<nSamples {
            let t = Float(n) * inv
            let f = freq * (1 + 0.18 * exp(-t / 0.04))
            phase += f * inv
            if phase > 1 { phase -= floor(phase) }
            let body = DSP.sine(phase) * exp(-t / 0.16)
            let skin = noiseHP.process(next() * 2 - 1) * 0.12 * exp(-t / 0.01)
            out[n] = body + skin
        }
        DSP.normalize(&out, peak: 0.36)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0003, fadeOut: 0.025)
        return out
    }

    private static func rim(sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(29, variant)
        let nSamples = Int(0.12 * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        var bp = DSP.Biquad.bandpass(freq: 900, q: 4.5, sampleRate: sampleRate)
        var hp = DSP.Biquad.highpass(freq: 2_400, q: 0.7, sampleRate: sampleRate)
        var phase: Float = 0
        for n in 0..<nSamples {
            let t = Float(n) * inv
            phase += 780 * inv
            if phase > 1 { phase -= floor(phase) }
            let wood = bp.process(DSP.sine(phase)) * exp(-t / 0.03)
            let click = hp.process(next() * 2 - 1) * exp(-t / 0.006)
            out[n] = wood * 0.6 + click * 0.5
        }
        DSP.normalize(&out, peak: 0.3)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0002, fadeOut: 0.012)
        return out
    }

    private static func crash(sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(31, variant)
        let nSamples = Int(1.4 * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        var hp = DSP.Biquad.highpass(freq: 2_800, q: 0.5, sampleRate: sampleRate)
        var bp = DSP.Biquad.bandpass(freq: 7_500, q: 0.6, sampleRate: sampleRate)
        for n in 0..<nSamples {
            let t = Float(n) * inv
            let nse = hp.process(bp.process(next() * 2 - 1))
            out[n] = nse * exp(-t / 0.42)
        }
        DSP.normalize(&out, peak: 0.28)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0004, fadeOut: 0.06)
        return out
    }

    private static func perc(sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(41, variant)
        let nSamples = Int(0.18 * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        var bp = DSP.Biquad.bandpass(freq: 420, q: 2.4, sampleRate: sampleRate)
        var phase: Float = 0
        for n in 0..<nSamples {
            let t = Float(n) * inv
            phase += 410 * inv
            if phase > 1 { phase -= floor(phase) }
            out[n] = bp.process(DSP.sine(phase) + (next() * 2 - 1) * 0.3) * exp(-t / 0.04)
        }
        DSP.normalize(&out, peak: 0.32)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0002, fadeOut: 0.015)
        return out
    }

    private static func shaker(sampleRate: Float, variant: Int) -> [Float] {
        let next = rng(43, variant)
        let nSamples = Int(0.22 * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        var hp = DSP.Biquad.highpass(freq: 6_000, q: 0.6, sampleRate: sampleRate)
        for n in 0..<nSamples {
            let t = Float(n) * inv
            out[n] = hp.process(next() * 2 - 1) * exp(-t / 0.07)
        }
        DSP.normalize(&out, peak: 0.22)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0002, fadeOut: 0.02)
        return out
    }

    private static func cowbell(sampleRate: Float, variant: Int) -> [Float] {
        let nSamples = Int(0.35 * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let inv = 1 / sampleRate
        var p0: Float = 0, p1: Float = 0
        for n in 0..<nSamples {
            let t = Float(n) * inv
            p0 += 540 * inv
            p1 += 800 * inv
            if p0 > 1 { p0 -= floor(p0) }
            if p1 > 1 { p1 -= floor(p1) }
            out[n] = (DSP.sine(p0) + DSP.sine(p1) * 0.7) * exp(-t / 0.12)
        }
        DSP.normalize(&out, peak: 0.3)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0002, fadeOut: 0.02)
        return out
    }
}
