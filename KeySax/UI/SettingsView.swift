import SwiftUI

struct SettingsView: View {
    var model: AppModel

    var body: some View {
        TabView {
            playbackTab
                .tabItem { Label("Horn", systemImage: "music.note") }
            mappingTab
                .tabItem { Label("Keys", systemImage: "keyboard") }
            midiTab
                .tabItem { Label("MIDI", systemImage: "pianokeys") }
        }
        .frame(width: 520, height: 460)
        .padding(8)
    }

    private var playbackTab: some View {
        Form {
            Section("Rows") {
                ForEach(KeyboardRow.allCases) { row in
                    Picker(row.hint, selection: rowBinding(row)) {
                        ForEach(VoiceID.allCases) { voice in
                            Text(voice.title).tag(voice)
                        }
                    }
                }
                Picker("Sax tone engine", selection: engineBinding) {
                    ForEach(ToneEngine.allCases) { engine in
                        Text(engine.title).tag(engine)
                    }
                }
                Text(model.settings.engine.subtitle)
                    .foregroundStyle(.secondary)
            }
            Section("Scale") {
                Picker("Scale", selection: scaleBinding) {
                    ForEach(ScaleKind.allCases) { scale in
                        Text(scale.title).tag(scale)
                    }
                }
                Picker("Root", selection: rootBinding) {
                    ForEach(RootNote.allCases) { root in
                        Text(root.title).tag(root)
                    }
                }
                Stepper("Octave \(model.settings.octave)", value: octaveBinding, in: 1...6)
                Stepper("Transpose \(model.settings.transpose)", value: transposeBinding, in: -12...12)
            }
            Section("Look") {
                Picker("Appearance", selection: appearanceBinding) {
                    ForEach(AppSettings.AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var mappingTab: some View {
        Form {
            Section("ABC / QWERTY") {
                Text("1–0, QWERTY, home row, and bottom row each play ten notes. Pick a sound on the row itself.")
                    .foregroundStyle(.secondary)
                LabeledContent("Number row", value: "1 2 3 4 5 6 7 8 9 0")
                LabeledContent("QWERTY", value: "Q W E R T Y U I O P")
                LabeledContent("Home", value: "A S D F G H J K L ;")
                LabeledContent("Bottom", value: "Z X C V B N M , . /")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var midiTab: some View {
        Form {
            Section("MIDI output") {
                Toggle("Send MIDI notes", isOn: midiBinding)
                Picker("Destination", selection: midiDestBinding) {
                    if model.audio.midi.destinationNames.isEmpty {
                        Text("No MIDI destinations").tag(0)
                    }
                    ForEach(Array(model.audio.midi.destinationNames.enumerated()), id: \.offset) { idx, name in
                        Text(name).tag(idx)
                    }
                }
                .onChange(of: model.settings.midiDestination) { _, value in
                    model.audio.midi.select(index: value)
                    model.settings.persist()
                }
                Button("Refresh destinations") {
                    model.audio.midi.refresh()
                }
            }
            Section("About") {
                Text("KeySax generates every sound on this Mac. No samples were licensed, no network is used, and nothing is uploaded.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func rowBinding(_ row: KeyboardRow) -> Binding<VoiceID> {
        Binding(
            get: { model.settings.voice(for: row) },
            set: { model.setRow(row, voice: $0) }
        )
    }

    private var engineBinding: Binding<ToneEngine> {
        Binding(
            get: { model.settings.engine },
            set: { model.setEngine($0) }
        )
    }

    private var scaleBinding: Binding<ScaleKind> {
        Binding(
            get: { model.settings.scale },
            set: { model.settings.scale = $0; model.settings.persist() }
        )
    }

    private var rootBinding: Binding<RootNote> {
        Binding(
            get: { model.settings.root },
            set: { model.settings.root = $0; model.settings.persist() }
        )
    }

    private var octaveBinding: Binding<Int> {
        Binding(
            get: { model.settings.octave },
            set: { model.settings.octave = $0; model.settings.persist() }
        )
    }

    private var transposeBinding: Binding<Int> {
        Binding(
            get: { model.settings.transpose },
            set: { model.settings.transpose = $0; model.settings.persist() }
        )
    }

    private var appearanceBinding: Binding<AppSettings.AppearanceMode> {
        Binding(
            get: { model.settings.appearance },
            set: { model.settings.appearance = $0; model.settings.persist() }
        )
    }

    private var midiBinding: Binding<Bool> {
        Binding(
            get: { model.settings.midiEnabled },
            set: { value in
                model.settings.midiEnabled = value
                model.audio.midi.enabled = value
                model.settings.persist()
            }
        )
    }

    private var midiDestBinding: Binding<Int> {
        Binding(
            get: { model.settings.midiDestination },
            set: { value in
                model.settings.midiDestination = value
                model.audio.midi.select(index: value)
                model.settings.persist()
            }
        )
    }
}
