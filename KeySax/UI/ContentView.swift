import SwiftUI
import AppKit

struct ContentView: View {
    var model: AppModel

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    private var scheme: ColorScheme {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .dark : .light
    }

    var body: some View {
        ZStack {
            KeySaxTheme.stageGradient(scheme: scheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopBar(model: model)
                Spacer(minLength: 16)
                InstrumentBoard(model: model)
                Spacer(minLength: 12)
                BottomBar(model: model)
            }

            if model.isPreparing {
                Color.black.opacity(scheme == .dark ? 0.28 : 0.08)
                    .ignoresSafeArea()
                PreparingView(
                    progress: model.prepareProgress,
                    status: model.prepareStatus,
                    accent: model.settings.voice(for: .numbers).accent
                )
            }

            if model.isRenderingVideo {
                Color.black.opacity(scheme == .dark ? 0.28 : 0.08)
                    .ignoresSafeArea()
                PreparingView(
                    progress: model.videoProgress,
                    status: "Letter frames",
                    accent: model.settings.voice(for: .numbers).accent
                )
            }
        }
        .preferredColorScheme(model.settings.appearance.colorScheme)
        .onAppear { model.start() }
        .sheet(isPresented: Binding(
            get: { model.showHelp },
            set: { model.showHelp = $0 }
        )) {
            HelpSheet(model: model)
        }
        .sheet(isPresented: Binding(
            get: { model.showSettings },
            set: { model.showSettings = $0 }
        )) {
            SettingsView(model: model)
        }
        .sheet(isPresented: Binding(
            get: { model.showExportSheet },
            set: { model.showExportSheet = $0 }
        )) {
            ExportSheet(model: model)
        }
        .focusable()
        .focusEffectDisabled()
        .onExitCommand { model.panic() }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: model.isPreparing)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.settings.rowVoices)
    }
}
