# KeySax

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A keyboard instrument in the browser. Press **1–0** and a saxophone answers — the YouTube number-key sax, as a PWA you can install on a phone, tablet, or computer.

Sounds are synthesized locally. Nothing is streamed, licensed, or uploaded. No account.

**https://emmi-dev12.github.io/KeySax/**

Tap **Tap to play**, then use the on-screen pads or a hardware keyboard. Install it:

- **Chrome / Edge** — Install app (download icon in the top bar, or the browser menu)
- **iPhone / iPad** — Share → Add to Home Screen
- **Safari on Mac** — File → Add to Dock

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
| Record | Letters drop, sentence forms, clip is ready on stop |
| Clear / ⌫ | Wipe the sentence, or delete the last letter |
| `⌘⇧R` | Record |
| `⌘⇧L` | Random solo |

### Export

Record while you play: letters drop down and the sentence writes itself at the bottom. Stop, and the clip is already there.

- **Video + audio** — the drop-letter clip with sound
- **Video only** — the same clip, silent
- **Audio only** — WAV

### Voices

Alto / Tenor / Bari / YouTube sax, piano, Rhodes, guitar, drums, kalimba, crystal glass, chimes, music box, soft pad, space thump.

Tone engine (Settings): **Classic Sax** or **Reed Model**. Settings persist in the browser.

## How the sound is made

Notes are rendered in the browser (no licensed samples):

- **Sax** — conical-bore harmonics, formant resonators, reed shaping, breath, chiff, delayed vibrato — or a waveguide reed model
- **Piano** — stretched partials, hammer noise, faster decay on high harmonics
- **Guitar** — plucked Karplus–Strong string with pick position and body resonances

## License

Original code and procedurally generated tones. Do not ship copyrighted commercial saxophone samples with this app — you do not need them.
