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
            WindowPaint(dark: scheme == .dark)
                .frame(width: 0, height: 0)

            KeySaxTheme.stageGradient(scheme: scheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopBar(model: model)
                Spacer(minLength: 16)
                InstrumentBoard(model: model)
                Spacer(minLength: 12)
                BottomBar(model: model)
            }
            .foregroundStyle(KeySaxTheme.ink(scheme))

            LetterRainOverlay(model: model)

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
                    status: "Finishing clip",
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

struct LetterRainOverlay: View {
    var model: AppModel

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let now = timeline.date
            GeometryReader { geo in
                ZStack {
                    ForEach(model.stageLetters) { drop in
                        let age = now.timeIntervalSince(drop.born)
                        let p = min(1, age / 0.48)
                        let ease = 1 - pow(1 - p, 3)
                        let fade: Double = {
                            if let ended = drop.ended {
                                return max(0, 1 - now.timeIntervalSince(ended) / 0.85)
                            }
                            return 1
                        }()
                        Text(drop.glyph == " " ? "␣" : drop.glyph)
                            .font(.system(size: drop.glyph.count > 2 ? 64 : 118, weight: .heavy, design: .rounded))
                            .foregroundStyle(drop.color.opacity(fade))
                            .shadow(color: .black.opacity(0.5 * fade), radius: 14, y: 8)
                            .position(
                                x: drop.xFrac * geo.size.width,
                                y: -36 + ease * (geo.size.height * 0.46)
                            )
                    }
                    VStack {
                        Spacer()
                        if !model.liveSentence.isEmpty {
                            Text(model.liveSentence)
                                .font(.system(size: sentenceSize(model.liveSentence.count), weight: .semibold, design: .rounded))
                                .foregroundStyle(KeySaxTheme.ivory.opacity(0.94))
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.55), radius: 10, y: 2)
                                .padding(.horizontal, 36)
                                .padding(.bottom, 28)
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func sentenceSize(_ n: Int) -> CGFloat {
        if n > 64 { return 22 }
        if n > 32 { return 28 }
        if n > 16 { return 34 }
        return 40
    }
}
