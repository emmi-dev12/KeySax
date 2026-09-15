import SwiftUI

struct HelpSheet: View {
    var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Four rows, pick a sound for each")
                .font(.system(size: 20, weight: .semibold, design: .rounded))

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
                row("Record", "Then pick letters, sentence, audio, or video")
                row("↑ / ↓", "Octave")
                row("[ / ]", "Transpose")
                row("Tab", "Sustain")
                row("Esc", "All notes off")
            }
            .font(.system(size: 14, design: .rounded))

            Text("Each row has its own menu — Alto Sax, piano, guitar, kalimba, glass, chimes, and more. ABC / QWERTY layout.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Close") { model.showHelp = false }
                    .buttonStyle(.glass)
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private func row(_ keys: String, _ meaning: String) -> some View {
        GridRow {
            Text(keys)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(meaning)
        }
    }
}

struct ExportSheet: View {
    var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Download")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            if let sentence = model.pendingTake?.sentence, !sentence.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(sentence)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            VStack(spacing: 8) {
                ForEach(ExportKind.allCases) { kind in
                    Button {
                        model.exportTake(kind)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kind.title)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Text(kind.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                Spacer()
                Button("Cancel") { model.showExportSheet = false }
                    .buttonStyle(.glass)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}

struct PreparingView: View {
    var progress: Double
    var status: String
    var accent: Color

    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress)
                .tint(accent)
                .frame(width: 240)
            Text(status == "Letter frames" ? "Cutting letter frames" : "Voicing the instruments")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Text(status)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .glassEffect(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
