# KeySax

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A native macOS instrument. Press **1–0** and a saxophone answers immediately — the YouTube number-key sax, as a real Mac app.

Sounds are synthesized on this Mac (additive sax plus an optional reed/waveguide engine). Nothing is streamed, licensed, or downloaded after install.

## Requirements

- macOS 27
- Apple Silicon (Universal `arm64 + x86_64` if you build with `scripts/build.sh`)
- Xcode 26+ **or** the macOS 27 Command Line Tools

## Open in Xcode

```bash
open /Users/mh/KeySax/KeySax.xcodeproj
```

Select the **KeySax** scheme, destination **My Mac**, and Run. Full Xcode is required for `xcodebuild`; Command Line Tools alone should use the script below.

The project targets **macOS 27**, uses Swift 6, SwiftUI, and Apple audio frameworks only (`AVAudioEngine`, Core Audio, CoreMIDI, Accelerate). No Electron, no web view, no accounts, no analytics.

## Build from the command line

This repo also builds without a full Xcode.app, using `swiftc`:

```bash
cd /Users/mh/KeySax
chmod +x scripts/build.sh
./scripts/build.sh
open build/KeySax.app
```

That produces a Universal (`arm64` + `x86_64`) `build/KeySax.app`. First launch synthesizes 61 chromatic notes × 2 variants (122 local WAVs) for the current preset, then caches them.

- Release, Universal by default
- Debug: `KEYSX_CONFIG=debug ./scripts/build.sh`
- Apple Silicon only: `KEYSX_UNIVERSAL=0 ./scripts/build.sh`

## Play

ABC / QWERTY. Each row has its own sound, octave, and transpose. Symbols play too (` - = [ ] \\ ; ' , . /). Shift types uppercase and `!@#` into letter videos.

| Row | Default |
| --- | --- |
| `` ` 1–0 - = `` | Alto Sax |
| `Q W E R T Y U I O P [ ] \\` | Kalimba |
| `A S D F G H J K L ; '` | Piano |
| `Z X C V B N M , . /` | Guitar |
| Space | Bass thump |

Pick **Drums**, Rhodes, glass, chimes, music box, pad, or any sax on a row.

| Key | Action |
| --- | --- |
| `↑` / `↓` | Bump every row’s octave |
| Per-row **OCT** / **TR** | Exact octave and transpose |
| `Tab` | Sustain |
| `Esc` | All notes off |
| Record | Then choose export |

### Export

After recording you can download:

- **Letters + audio** — one letter per frame, with sound
- **Letters only** — silent video
- **Sentence + audio** — letters, then the spelled sentence
- **Sentence only** — just the sentence card
- **Audio only** — WAV

### Voices

Alto / Tenor / Bari / YouTube sax, piano, Rhodes, guitar, drums, kalimba, crystal glass, chimes, music box, soft pad, space thump.

Tone engine (Settings): **Classic Sax** or **Reed Model**.

Settings persist in `UserDefaults`.

## How the sound is made

On first launch KeySax renders local banks for sax, piano, and guitar (no licensed samples):

- **Sax** — conical-bore harmonics, formant resonators, reed shaping, breath, chiff, delayed vibrato
- **Piano** — stretched partials, hammer noise, faster decay on high harmonics
- **Guitar** — plucked Karplus–Strong string with pick position and body resonances

Buffers are cached as 16-bit WAVs in:

```
~/Library/Application Support/KeySax/Banks/
```

Playback is `AVAudioEngine` + a pool of `AVAudioPlayerNode`s, preloaded in memory. The I/O buffer is requested at 128 frames for low latency. No network is required after install.

## Project layout

```
KeySax/
  KeySaxApp.swift          SwiftUI app entry
  App/                     settings + session model
  Audio/                   synthesis, cache, engine, recorder
  Music/                   scales, key map, random solo
  Input/                   local NSEvent key monitor
  MIDI/                    CoreMIDI output
  UI/                      pad, chrome, settings, waveform
  Assets.xcassets          app icon
  Resources/AppIcon.icns
```

## License

Original code and procedurally generated tones. Do not ship copyrighted commercial saxophone samples with this app — you do not need them.
