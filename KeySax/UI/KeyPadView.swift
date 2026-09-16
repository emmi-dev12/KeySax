import SwiftUI
import AppKit

struct InstrumentBoard: View {
    var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(KeyboardRow.allCases) { row in
                RowStrip(model: model, row: row)
            }
            SpaceBarPad(model: model)
        }
        .padding(.horizontal, 28)
    }
}

struct RowStrip: View {
    var model: AppModel
    var row: KeyboardRow
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let voice = model.settings.voice(for: row)
        let keys = model.notes(for: row)
        let down = model.pressed[row] ?? []
        let ready = model.audio.isReady(voice)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(row.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(KeySaxTheme.muted(scheme))
                    .frame(width: 72, alignment: .leading)
                VoiceMenu(model: model, row: row)
                if model.loadingVoice.contains(voice) {
                    ProgressView().controlSize(.mini)
                }
                Spacer()
                RowStepper(
                    label: "OCT",
                    text: "\(model.settings.octave(for: row))",
                    down: { model.settings.setOctave(model.settings.octave(for: row) - 1, for: row) },
                    up: { model.settings.setOctave(model.settings.octave(for: row) + 1, for: row) }
                )
                RowStepper(
                    label: "TR",
                    text: {
                        let t = model.settings.transpose(for: row)
                        return t == 0 ? "0" : (t > 0 ? "+\(t)" : "\(t)")
                    }(),
                    down: { model.settings.setTranspose(model.settings.transpose(for: row) - 1, for: row) },
                    up: { model.settings.setTranspose(model.settings.transpose(for: row) + 1, for: row) }
                )
            }
            HStack(spacing: 8) {
                ForEach(keys) { key in
                    RoundPad(
                        glyph: key.label,
                        note: key.noteName,
                        pressed: down.contains(key.index),
                        fill: voice.accent,
                        enabled: ready,
                        onDown: { model.play(row: row, index: key.index) },
                        onUp: { model.release(row: row, index: key.index) }
                    )
                }
            }
        }
    }
}

struct RowStepper: View {
    var label: String
    var text: String
    var down: () -> Void
    var up: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(KeySaxTheme.muted(scheme))
            Button(action: down) { Image(systemName: "minus") }
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(minWidth: 22)
            Button(action: up) { Image(systemName: "plus") }
        }
        .buttonStyle(.borderless)
        .controlSize(.mini)
    }
}

struct VoiceMenu: View {
    var model: AppModel
    var row: KeyboardRow
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let current = model.settings.voice(for: row)
        Menu {
            ForEach(VoiceID.groups, id: \.0) { group, voices in
                Section(group) {
                    ForEach(voices) { voice in
                        Button {
                            model.setRow(row, voice: voice)
                        } label: {
                            if voice == current {
                                Label(voice.title, systemImage: "checkmark")
                            } else {
                                Text(voice.title)
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(current.accent)
                    .frame(width: 7, height: 7)
                Text(current.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(KeySaxTheme.muted(scheme))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(KeySaxTheme.glassFill(scheme), in: Capsule())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Sound for the \(row.hint)")
    }
}

struct RoundPad: View {
    var glyph: String
    var note: String
    var pressed: Bool
    var fill: Color
    var enabled: Bool
    var onDown: () -> Void
    var onUp: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 3) {
                Text(glyph)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(pressed ? Color.white.opacity(0.9) : KeySaxTheme.muted(scheme))
                Text(note)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(pressed ? Color.white : KeySaxTheme.ink(scheme).opacity(0.92))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(pressed ? fill : fill.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(fill.opacity(pressed ? 0.9 : 0.35), lineWidth: 1)
            )
            .scaleEffect(pressed ? 0.96 : 1)
        }
        .buttonStyle(.plain)
        .buttonRepeatBehavior(.disabled)
        .disabled(!enabled)
        .animation(.easeOut(duration: 0.12), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if enabled { onDown() } }
                .onEnded { _ in onUp() }
        )
        .accessibilityLabel("\(glyph), \(note)")
    }
}

struct SpaceBarPad: View {
    var model: AppModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ready = model.audio.isReady(.thump)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("SPACE")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(KeySaxTheme.muted(scheme))
                    .frame(width: 72, alignment: .leading)
                Text("Space Thump")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(KeySaxTheme.muted(scheme))
                if model.loadingVoice.contains(.thump) {
                    ProgressView().controlSize(.mini)
                }
                Spacer()
            }
            Button(action: {}) {
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        Text("space")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(model.spacePressed ? Color.white.opacity(0.9) : KeySaxTheme.muted(scheme))
                        Text(Pitch.displayName(midi: model.spaceMIDI))
                            .font(.system(size: 15, weight: .semibold, design: .serif))
                            .foregroundStyle(model.spacePressed ? Color.white : KeySaxTheme.ink(scheme).opacity(0.92))
                    }
                    Spacer()
                }
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(model.spacePressed ? VoiceID.thump.accent : VoiceID.thump.accent.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(VoiceID.thump.accent.opacity(model.spacePressed ? 0.9 : 0.35), lineWidth: 1)
                )
                .scaleEffect(model.spacePressed ? 0.985 : 1)
            }
            .buttonStyle(.plain)
            .buttonRepeatBehavior(.disabled)
            .disabled(!ready)
            .animation(.easeOut(duration: 0.12), value: model.spacePressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if ready { model.playSpace() } }
                    .onEnded { _ in model.releaseSpace() }
            )
            .accessibilityLabel("Space, bass thump \(Pitch.displayName(midi: model.spaceMIDI))")
        }
    }
}
