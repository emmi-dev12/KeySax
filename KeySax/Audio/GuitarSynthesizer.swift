import Foundation

enum GuitarSynthesizer {
    static func render(midi: Int, sampleRate: Float, variant: Int, duration: Float = 2.5) -> [Float] {
        var rng = UInt64(midi &* 4_241 &+ variant &* 8_081 &+ 11)
        func next() -> Float {
            rng = rng &* 6_364_136_223_846_793_005 &+ 1
            return Float(Double((rng >> 33) & 0xFFFFFFFF) / Double(UInt32.max))
        }

        let f0 = DSP.midiToHz(midi)
        let nSamples = Int(duration * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let delayLen = max(8, Int((sampleRate / f0).rounded()))
        var buf = [Float](repeating: 0, count: delayLen)
        let pick = max(2, Int(Float(delayLen) * (0.12 + next() * 0.18)))
        for i in 0..<delayLen {
            let burst = (next() * 2 - 1)
            let window = sin(Float.pi * Float(i) / Float(delayLen))
            let comb: Float = i < pick ? 1 : -0.35
            buf[i] = burst * window * comb
        }
        var idx = 0
        var prev: Float = 0
        let damp: Float = 0.988 - min(0.04, f0 / 18_000) + (next() - 0.5) * 0.004
        var body1 = DSP.Biquad.bandpass(freq: 110, q: 3.2, sampleRate: sampleRate)
        var body2 = DSP.Biquad.peaking(freq: 420, q: 2.4, gainDB: 3.5, sampleRate: sampleRate)
        var body3 = DSP.Biquad.peaking(freq: 850, q: 2.0, gainDB: 2.2, sampleRate: sampleRate)
        var pickHP = DSP.Biquad.highpass(freq: 1_200, q: 0.7, sampleRate: sampleRate)
        var dc = DSP.Biquad.highpass(freq: 50, q: 0.7, sampleRate: sampleRate)
        var brightness = DSP.OnePole()
        let invSR = 1 / sampleRate
        let pickAmt = 0.22 + next() * 0.1

        for n in 0..<nSamples {
            let t = Float(n) * invSR
            let x0 = buf[idx]
            let x1 = buf[(idx + 1) % delayLen]
            let avg = (x0 + x1) * 0.5 * damp
            let stretched = avg * 0.82 + prev * 0.18
            prev = avg
            buf[idx] = stretched
            idx = (idx + 1) % delayLen

            let pickEnv = exp(-t / 0.012) * min(1, t / 0.0008)
            var y = x0 + pickHP.process(x0) * pickAmt * pickEnv
            y += body1.process(x0) * 0.35
            y = body2.process(y)
            y = body3.process(y)
            y = brightness.lowpass(y, cutoff: 0.18 + exp(-t / 0.4) * 0.15)
            y = dc.process(y)
            let env = min(1, t / 0.003) * exp(-t / (1.15 + 220 / f0))
            out[n] = y * env
        }

        DSP.normalize(&out, peak: 0.33)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0005, fadeOut: 0.03)
        return out
    }
}
