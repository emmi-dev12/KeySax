import Foundation

enum ReedSynthesizer {
    static func render(
        midi: Int,
        sampleRate: Float,
        preset: SaxPreset,
        variant: Int,
        duration: Float = 1.9
    ) -> [Float] {
        var rng = UInt64(midi &* 11_017 &+ variant &* 42_421 &+ 7)
        func next() -> Float {
            rng = rng &* 6_364_136_223_846_793_005 &+ 1
            return Float(Double((rng >> 33) & 0xFFFFFFFF) / Double(UInt32.max))
        }

        let f0 = DSP.midiToHz(midi)
        let nSamples = Int(duration * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        var delay = DSP.FracDelay(maxLength: max(64, Int(sampleRate / 40) + 8))
        var boreLP = DSP.OnePole()
        var bell = DSP.Biquad.lowpass(freq: 1_100 + preset.brightness * 4_400, q: 0.7, sampleRate: sampleRate)
        var form1 = DSP.Biquad.bandpass(freq: preset.formants.first?.freq ?? 800, q: 3.4, sampleRate: sampleRate)
        var form2 = DSP.Biquad.bandpass(freq: preset.formants.dropFirst().first?.freq ?? 1_400, q: 2.8, sampleRate: sampleRate)
        var breathBP = DSP.Biquad.bandpass(freq: preset.breathFreq, q: 1.1, sampleRate: sampleRate)
        var dc = DSP.Biquad.highpass(freq: 40, q: 0.7, sampleRate: sampleRate)

        let attack: Float = 0.016
        let decay: Float = 0.1
        let sustain: Float = 0.8
        let hold = duration - attack - decay - 0.05
        let invSR = 1 / sampleRate
        let vibPhase = next()
        let stiffness = 2.4 + preset.saturation * 1.2
        var wander: Float = 0

        for n in 0..<nSamples {
            let t = Float(n) * invSR
            let env = DSP.adsr(
                n: n,
                sampleRate: sampleRate,
                attack: attack,
                decay: decay,
                sustain: sustain,
                release: 0.05,
                hold: hold
            )
            var pressure = 0.7 * env
            if t < 0.05 { pressure *= 0.5 + 0.5 * (t / 0.05) }

            wander += (next() - 0.5) * 0.08
            wander *= 0.997
            var vib: Float = 0
            if t > preset.vibratoDelay {
                let vt = t - preset.vibratoDelay
                vib = DSP.sine(vibPhase + preset.vibratoRate * vt) * preset.vibratoDepth * min(1, vt / 0.2)
            }
            var scoopEnv: Float = 1
            if t < 0.06 {
                let x = t / 0.06
                scoopEnv = DSP.centsToRatio(-preset.scoopCents * (1 - x) * (1 - x))
            }
            let freq = f0 * scoopEnv * DSP.centsToRatio(vib + wander)
            let delaySamp = max(4, sampleRate / freq)

            let y = delay.read(delaySamp)
            let noise = next() * 2 - 1
            let delta = pressure - y
            let reed = DSP.tanhApprox(delta * stiffness)
            let flow = reed * 0.58 + noise * (0.035 + preset.breath * 0.4) * pressure
            let intoBore = flow + y * (0.84 + 0.08 * (1 - preset.brightness))
            let lost = boreLP.lowpass(intoBore, cutoff: 0.16 + preset.brightness * 0.38)
            delay.write(lost)

            var tone = y + flow * 0.18
            tone = bell.process(tone)
            tone = tone * 0.55 + form1.process(tone) * 0.5 + form2.process(tone) * 0.28
            let breath = breathBP.process(noise) * preset.breath * env
            var s = (tone + breath) * env
            if preset.growl > 0 {
                s *= 1 + preset.growl * DSP.sine(0.3 + 66 * t)
            }
            s = dc.process(s)
            out[n] = s
        }

        DSP.normalize(&out, peak: 0.32)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0015, fadeOut: 0.025)
        return out
    }
}
