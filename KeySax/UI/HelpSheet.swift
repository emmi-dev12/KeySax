import SwiftUI

struct HelpSheet: View {
    var model: AppModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Four rows, pick a sound for each")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(KeySaxTheme.ink(scheme))

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                row("1 – 0", "Number row")
                row("Q W E R T Y U I O P", "QWERTY row")
                row("A S D F G H J K L ;", "Home row")
                row("Z X C V B N M , . /", "Bottom row")
                row("Space", "Bass thump")
                row("Drums", "Pick Drums on any row")
                row("` - = [ ] \\ ; '", "Symbols also play")
                row("Shift + key", "Uppercase / ! @ # in the video")
                row("OCT / TR", "Octave and transpose per row")
                row("Record", "Letters drop, sentence forms, clip is ready on stop")
                row("Clear / ⌫", "Wipe the sentence, or delete the last letter")
                row("↑ / ↓", "Octave")
                row("Tab", "Sustain")
                row("Esc", "All notes off")
            }
            .font(.system(size: 14, design: .rounded))

            Text("Each row has its own menu — Alto Sax, piano, guitar, kalimba, glass, chimes, and more. ABC / QWERTY layout.")
                .font(.callout)
                .foregroundStyle(KeySaxTheme.muted(scheme))

            HStack {
                Spacer()
                Button("Close") { model.showHelp = false }
                    .buttonStyle(GlassCapsuleButtonStyle())
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 460)
        .foregroundStyle(KeySaxTheme.ink(scheme))
        .background(KeySaxTheme.sheetFill)
    }

    private func row(_ keys: String, _ meaning: String) -> some View {
        GridRow {
            Text(keys)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(KeySaxTheme.glassFill(scheme), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(meaning)
                .foregroundStyle(KeySaxTheme.ink(scheme))
        }
    }
}

struct ExportSheet: View {
    var model: AppModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Download")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(KeySaxTheme.ink(scheme))
            if let sentence = model.pendingTake?.sentence, !sentence.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(sentence)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(KeySaxTheme.muted(scheme))
                    .textSelection(.enabled)
            }
            VStack(spacing: 8) {
                ForEach([ExportKind.lettersAudio, .lettersVideo, .audioOnly]) { kind in
                    Button {
                        model.exportTake(kind)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kind.title)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(KeySaxTheme.ink(scheme))
                            Text(kind.detail)
                                .font(.caption)
                                .foregroundStyle(KeySaxTheme.muted(scheme))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(KeySaxTheme.glassFill(scheme), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                Spacer()
                Button("Cancel") { model.showExportSheet = false }
                    .buttonStyle(GlassCapsuleButtonStyle())
            }
        }
        .padding(24)
        .frame(width: 420)
        .background(KeySaxTheme.sheetFill)
    }
}

struct PreparingView: View {
    var progress: Double
    var status: String
    var accent: Color
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress)
                .tint(accent)
                .frame(width: 240)
            Text(status == "Letter frames" ? "Cutting letter frames" : "Voicing the instruments")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(KeySaxTheme.ink(scheme))
            Text(status)
                .font(.callout)
                .foregroundStyle(KeySaxTheme.muted(scheme))
        }
        .padding(28)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(KeySaxTheme.glassFill(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(KeySaxTheme.glassStroke(scheme), lineWidth: 1)
                )
        }
    }
}
