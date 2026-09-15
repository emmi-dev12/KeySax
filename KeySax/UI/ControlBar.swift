import SwiftUI
import AppKit

struct TopBar: View {
    var model: AppModel

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text("KeySax")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text(model.statusLine)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            WaveformView(
                bins: model.spectrum,
                level: model.level,
                accent: model.settings.voice(for: .numbers).accent,
                compact: true
            )
            .frame(width: 160)

            Button {
                model.showHelp = true
            } label: {
                Image(systemName: "questionmark")
            }
            .buttonStyle(.glass)
            .help("Play guide")

            Button {
                model.showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .buttonStyle(.glass)
            .help("Settings")
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
    }
}

struct BottomBar: View {
    var model: AppModel

    var body: some View {
        HStack(spacing: 10) {
            GlassSurface {
                HStack(spacing: 8) {
                    Button {
                        model.settings.bumpOctave(-1)
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .help("Octave down (↓)")
                    VStack(spacing: 0) {
                        Text("OCT")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("\(model.settings.octave)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                    .frame(minWidth: 36)
                    Button {
                        model.settings.bumpOctave(1)
                    } label: {
                        Image(systemName: "chevron.up")
                    }
                    .help("Octave up (↑)")
                }
                .buttonStyle(.glass)
            }

            GlassSurface {
                HStack(spacing: 8) {
                    Button {
                        model.settings.bumpTranspose(-1)
                    } label: {
                        Image(systemName: "minus")
                    }
                    Text(transLabel)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .frame(minWidth: 28)
                    Button {
                        model.settings.bumpTranspose(1)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                .buttonStyle(.glass)
                .help("Transpose  ( [  ] )")
            }

            GlassSurface {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(KeySaxTheme.brass)
                        .font(.system(size: 12))
                    Slider(value: volumeBinding, in: 0...1)
                        .controlSize(.small)
                        .frame(width: 110)
                }
            }

            GlassSurface {
                Toggle(isOn: sustainBinding) {
                    Text("Sustain")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
            }
            .help("Tab")

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                Button {
                    model.settings.letterVideo.toggle()
                    model.settings.persist()
                } label: {
                    Image(systemName: model.settings.letterVideo ? "textformat" : "textformat")
                }
                .opacity(model.settings.letterVideo ? 1 : 0.4)
                .help(model.settings.letterVideo ? "Letter video on — each key is a frame" : "Letter video off")

                Button {
                    model.toggleRecord()
                } label: {
                    Image(systemName: model.isRecording ? "stop.circle.fill" : (model.settings.letterVideo ? "record.circle" : "record.circle"))
                }
                .tint(model.isRecording ? .red : nil)
                .help(model.isRecording ? timeString : (model.settings.letterVideo ? "Record letter video" : "Record WAV"))

                Button {
                    model.toggleSolo()
                } label: {
                    Image(systemName: "sparkles")
                }
                .help("Random sax solo")

                Button {
                    model.toggleMIDI()
                } label: {
                    Image(systemName: "pianokeys")
                }
                .opacity(model.settings.midiEnabled ? 1 : 0.55)
                .help("MIDI out")
            }
            .buttonStyle(.glass)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 14)
    }

    private var transLabel: String {
        let t = model.settings.transpose
        if t == 0 { return "0" }
        return t > 0 ? "+\(t)" : "\(t)"
    }

    private var timeString: String {
        let s = Int(model.recordElapsed)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private var volumeBinding: Binding<Double> {
        Binding(
            get: { model.settings.volume },
            set: { model.setVolume($0) }
        )
    }

    private var sustainBinding: Binding<Bool> {
        Binding(
            get: { model.settings.sustain },
            set: { _ in model.toggleSustain() }
        )
    }
}
