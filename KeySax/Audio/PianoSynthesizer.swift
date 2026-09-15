import Foundation

enum PianoSynthesizer {
    static func render(midi: Int, sampleRate: Float, variant: Int, duration: Float = 2.8) -> [Float] {
        var rng = UInt64(midi &* 9_917 &+ variant &* 13_331 &+ 3)
        func next() -> Float {
            rng = rng &* 6_364_136_223_846_793_005 &+ 1
            return Float(Double((rng >> 33) & 0xFFFFFFFF) / Double(UInt32.max))
        }

        let f0 = DSP.midiToHz(midi)
        let nSamples = Int(duration * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let invSR = 1 / sampleRate
        let nyquist = sampleRate * 0.46
        let stiffness = 0.00012 + 0.00022 * pow(max(0, 72 - Float(midi)) / 48, 1.4)
        let hCount = min(28, max(8, Int(nyquist / f0)))
        var phases = (0..<hCount).map { _ in next() }
        var weights = [Float](repeating: 0, count: hCount)
        var sum: Float = 0
        for h in 1...hCount {
            var w = 1 / pow(Float(h), 1.05)
            if h == 1 { w *= 1.0 }
            if h == 2 { w *= 0.72 }
            if h == 3 { w *= 0.4 }
            let freq = f0 * Float(h)
            let hammer = exp(-pow((freq - 2_400) / 2_600, 2))
            w *= 0.55 + 0.7 * hammer
            weights[h - 1] = w
            sum += w
        }
        if sum > 0 { for i in weights.indices { weights[i] /= sum } }

        var hammerHP = DSP.Biquad.highpass(freq: 800, q: 0.7, sampleRate: sampleRate)
        var hammerBP = DSP.Biquad.bandpass(freq: 2_800, q: 0.8, sampleRate: sampleRate)
        var board = DSP.Biquad.peaking(freq: max(80, f0 * 0.5), q: 4.5, gainDB: 2.2, sampleRate: sampleRate)
        var dc = DSP.Biquad.highpass(freq: 30, q: 0.7, sampleRate: sampleRate)
        var tone = DSP.OnePole()

        let vel = 0.86 + next() * 0.14
        let decayBase = 2.1 + (f0 / 440) * 0.55
        let hammerAmt = 0.16 * vel

        for n in 0..<nSamples {
            let t = Float(n) * invSR
            var s: Float = 0
            for h in 1...hCount {
                let fh = f0 * Float(h) * sqrt(1 + stiffness * Float(h * h))
                if fh > nyquist { continue }
                phases[h - 1] += fh * invSR
                if phases[h - 1] > 1 { phases[h - 1] -= floor(phases[h - 1]) }
                let decay = exp(-t * (decayBase + Float(h) * 0.62))
                s += weights[h - 1] * DSP.sine(phases[h - 1]) * decay
            }

            let noise = next() * 2 - 1
            let hamEnv = exp(-t / 0.006) * min(1, t / 0.0006)
            let hammer = hammerBP.process(hammerHP.process(noise)) * hammerAmt * hamEnv
            let attack = min(1, t / 0.004)
            var y = (s * attack + hammer) * vel
            y = board.process(y)
            y = tone.lowpass(y, cutoff: 0.22 + vel * 0.2)
            y = dc.process(y)
            out[n] = y
        }

        DSP.normalize(&out, peak: 0.36)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0004, fadeOut: 0.04)
        return out
    }
}
