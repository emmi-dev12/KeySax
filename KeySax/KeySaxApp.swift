import SwiftUI

@MainActor
enum KeySaxRuntime {
    static let model = AppModel()
}

@main
struct KeySaxApp: App {
    private var model: AppModel { KeySaxRuntime.model }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .frame(minWidth: 980, minHeight: 740)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1120, height: 860)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appSettings) {
                Button("Play Guide") { model.showHelp = true }
                    .keyboardShortcut("?", modifiers: [.command])
            }
            CommandMenu("Play") {
                Button("Sustain") { model.toggleSustain() }
                Button(model.settings.letterVideo ? "Letter Video On" : "Letter Video Off") {
                    model.settings.letterVideo.toggle()
                    model.settings.persist()
                }
                Button(model.isRecording ? "Stop Recording" : "Record") {
                    model.toggleRecord()
                }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                Button("Random Sax Solo") { model.toggleSolo() }
                    .keyboardShortcut("l", modifiers: [.command, .shift])
                Button("All Notes Off") { model.panic() }
                    .keyboardShortcut(".", modifiers: [.command])
                Divider()
                Button("Octave Down") { model.settings.bumpOctave(-1) }
                Button("Octave Up") { model.settings.bumpOctave(1) }
            }
        }

        Settings {
            SettingsView(model: model)
        }
    }
}
