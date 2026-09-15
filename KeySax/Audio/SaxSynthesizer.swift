import Foundation

enum SaxSynthesizer {
    static func render(
        midi: Int,
        sampleRate: Float,
        preset: SaxPreset,
        variant: Int,
        duration: Float = 1.9
    ) -> [Float] {
        var rng = UInt64(midi &* 16_807 &+ variant &* 97_351 &+ 13)
        func next() -> Float {
            rng = rng &* 6_364_136_223_846_793_005 &+ 1
            return Float(Double((rng >> 33) & 0xFFFFFFFF) / Double(UInt32.max))
        }

        let f0 = DSP.midiToHz(midi)
        let nSamples = Int(duration * sampleRate)
        var out = [Float](repeating: 0, count: nSamples)
        let nyquist = sampleRate * 0.45
        let invSR = 1 / sampleRate

        let detuneCents = (next() - 0.5) * 5
        let breathAmt = preset.breath * (0.9 + next() * 0.25)
        let chiffAmt = preset.chiff * (0.85 + next() * 0.3)
        let vibDepth = preset.vibratoDepth * (0.9 + next() * 0.2)
        let vibPhase = next()
        let vibPhase2 = next()
        let growlPhase = next()
        let scoop = preset.scoopCents * (0.88 + next() * 0.22)
        let drive = 1.15 + preset.saturation * 1.4
        let evenAsym = 0.18 + preset.evenBoost * 0.08

        let hCount = min(preset.harmonicCount, max(8, Int(nyquist / f0)))
        var phases = [Float](repeating: 0, count: hCount)
        for i in 0..<hCount { phases[i] = next() }

        var weights = [Float](repeating: 0, count: hCount)
        var weightSum: Float = 0
        let track = 1 + 0.07 * log2(max(f0 / 440, 0.25))
        for h in 1...hCount {
            let freq = f0 * Float(h)
            if freq > nyquist { continue }
            var w = 1 / pow(Float(h), preset.rolloff)
            if h == 1 { w *= 1.0 }
            else if h == 2 { w *= 1.22 * preset.evenBoost }
            else if h == 3 { w *= 0.78 * preset.oddBoost }
            else { w *= (h % 2 == 1) ? preset.oddBoost : preset.evenBoost }
            let logf = log2(max(freq, 20))
            for formant in preset.formants {
                let d = logf - log2(formant.freq * track)
                w *= 1 + formant.gain * exp(-d * d / (2 * formant.bandwidth * formant.bandwidth))
            }
            if freq > 1800 && freq < 3800 { w *= 1.18 }
            weights[h - 1] = w
            weightSum += w
        }
        if weightSum > 0 {
            for i in weights.indices { weights[i] /= weightSum }
        }

        var formantBP: [DSP.Biquad] = preset.formants.prefix(4).map { f in
            DSP.Biquad.bandpass(freq: f.freq * track, q: 3.6, sampleRate: sampleRate)
        }
        var presence = DSP.Biquad.peaking(freq: 2_700 * track, q: 1.4, gainDB: 2.8 + preset.brightness * 2, sampleRate: sampleRate)
        var bell = DSP.Biquad.lowpass(freq: 1_200 + preset.brightness * 5_800, q: 0.68, sampleRate: sampleRate)
        var breathBP = DSP.Biquad.bandpass(freq: preset.breathFreq, q: 1.15, sampleRate: sampleRate)
        var breathHP = DSP.Biquad.highpass(freq: 1_400, q: 0.7, sampleRate: sampleRate)
        var chiffBP = DSP.Biquad.bandpass(freq: 4_200, q: 0.7, sampleRate: sampleRate)
        var dcHP = DSP.Biquad.highpass(freq: 45, q: 0.7, sampleRate: sampleRate)
        var shelf = DSP.Biquad.highshelf(freq: 3_200, gainDB: 1.5 + preset.brightness * 3, sampleRate: sampleRate)
        var toneLP = DSP.OnePole()
        var pink1: Float = 0, pink2: Float = 0
        var wander: Float = 0

        let attack: Float = midi < 55 ? 0.024 : 0.014
        let decay: Float = 0.11
        let sustain: Float = 0.8
        let hold = duration - attack - decay - 0.05

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
            let bloom = 1 + 0.07 * (1 - exp(-t / 0.2))
            let brightAttack = 1 + 0.35 * exp(-t / 0.055)

            wander += (next() - 0.5) * 0.09
            wander *= 0.997
            var scoopEnv: Float = 1
            if t < 0.07 {
                let x = t / 0.07
                scoopEnv = DSP.centsToRatio(-scoop * (1 - x) * (1 - x))
            }
            var vib: Float = 0
            if t > preset.vibratoDelay {
                let vt = t - preset.vibratoDelay
                let fade = min(1, vt / 0.22)
                let lfo = DSP.sine(vibPhase + preset.vibratoRate * vt)
                    + 0.14 * DSP.sine(vibPhase2 + preset.vibratoRate * 2.02 * vt)
                vib = lfo * vibDepth * fade
            }
            let freq = f0 * scoopEnv * DSP.centsToRatio(detuneCents + vib + wander)

            var body: Float = 0
            for h in 1...hCount {
                let w = weights[h - 1]
                if w == 0 { continue }
                let inharm = 1 + 0.00012 * Float(h * h)
                phases[h - 1] += freq * Float(h) * inharm * invSR
                if phases[h - 1] > 1 { phases[h - 1] -= floor(phases[h - 1]) }
                body += w * DSP.sine(phases[h - 1])
            }

            let pulse = DSP.reedShape(DSP.sine(phases[0]), drive: drive, even: evenAsym)
            var sig = body * 0.62 + pulse * 0.38

            var form: Float = 0
            for i in formantBP.indices {
                let mix: Float = i == 0 ? 0.9 : (i == 1 ? 0.55 : 0.32)
                form += formantBP[i].process(sig) * mix
            }
            sig = sig * 0.42 + form * 0.58
            sig = presence.process(sig)
            sig = shelf.process(sig)
            let lpCut = min(0.55, 0.08 + preset.brightness * 0.28 * env * brightAttack)
            sig = toneLP.lowpass(sig, cutoff: lpCut)
            sig = bell.process(sig)

            let wnoise = next() * 2 - 1
            pink1 = 0.997 * pink1 + 0.029 * wnoise
            pink2 = 0.985 * pink2 + 0.14 * wnoise
            let air = pink1 + 0.45 * pink2 + 0.08 * wnoise
            let breath = breathHP.process(breathBP.process(air)) * breathAmt * (0.45 + 0.55 * env)
            let chiff = chiffBP.process(wnoise) * chiffAmt * exp(-t / 0.022) * min(1, t / 0.002)
            let click = t < 0.003 ? wnoise * 0.08 * (1 - t / 0.003) : 0

            var growl: Float = 1
            if preset.growl > 0 {
                growl = 1 + preset.growl * DSP.sine(growlPhase + 62 * t) * env
            }
            let ampVib = 1 + preset.ampVibrato * DSP.sine(vibPhase + 0.21 + preset.vibratoRate * t)
            var y = (sig * growl + breath + chiff + click) * env * bloom * ampVib
            y = dcHP.process(y)
            if preset.saturation > 0 {
                y = DSP.reedShape(y, drive: 1 + preset.saturation * 0.7, even: 0.12)
            }
            out[n] = y
        }

        DSP.normalize(&out, peak: 0.34)
        DSP.applyFade(&out, sampleRate: sampleRate, fadeIn: 0.0012, fadeOut: 0.025)
        return out
    }
}
