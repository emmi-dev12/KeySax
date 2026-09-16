import SwiftUI
import AppKit

enum KeySaxTheme {
    static let brass = Color(red: 0.863, green: 0.702, blue: 0.349)
    static let brassDeep = Color(red: 0.48, green: 0.32, blue: 0.14)
    static let ivory = Color(red: 0.957, green: 0.925, blue: 0.886)
    static let ebony = Color(red: 0.059, green: 0.043, blue: 0.039)
    static let wood = Color(red: 0.161, green: 0.102, blue: 0.071)
    static let nickel = Color(red: 0.78, green: 0.76, blue: 0.70)
    static let stageDark = Color(red: 0.059, green: 0.043, blue: 0.039)
    static let stageMid = Color(red: 0.161, green: 0.102, blue: 0.071)

    static let ink = ivory
    static let muted = ivory.opacity(0.55)
    static let primaryText = ivory.opacity(0.92)
    static let glassFill = Color.white.opacity(0.08)
    static let glassStroke = Color.white.opacity(0.14)
    static let sheetFill = Color(red: 0.110, green: 0.078, blue: 0.063).opacity(0.92)

    static func stageGradient(scheme: ColorScheme) -> RadialGradient {
        if scheme == .dark {
            return RadialGradient(
                colors: [stageMid, stageDark],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 40,
                endRadius: 640
            )
        }
        return RadialGradient(
            colors: [
                Color(red: 0.97, green: 0.94, blue: 0.88),
                Color(red: 0.82, green: 0.74, blue: 0.64)
            ],
            center: UnitPoint(x: 0.5, y: 0.42),
            startRadius: 40,
            endRadius: 640
        )
    }

    static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ivory : Color(red: 0.110, green: 0.078, blue: 0.055)
    }

    static func muted(_ scheme: ColorScheme) -> Color {
        ink(scheme).opacity(0.55)
    }

    static func glassFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.46)
    }

    static func glassStroke(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.55)
    }
}

struct GlassSurface<Content: View>: View {
    var corner: CGFloat = 16
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(KeySaxTheme.glassFill(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .strokeBorder(KeySaxTheme.glassStroke(scheme), lineWidth: 1)
                    )
            }
    }
}

struct GlassIconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 32, height: 32)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(KeySaxTheme.glassFill(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(KeySaxTheme.glassStroke(scheme), lineWidth: 1)
                    )
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct GlassCapsuleButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(KeySaxTheme.glassFill(scheme))
                    .overlay(Capsule().strokeBorder(KeySaxTheme.glassStroke(scheme), lineWidth: 1))
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct WindowPaint: NSViewRepresentable {
    var dark: Bool

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isOpaque = true
            if dark {
                window.backgroundColor = NSColor(red: 0.059, green: 0.043, blue: 0.039, alpha: 1)
                window.appearance = NSAppearance(named: .darkAqua)
            } else {
                window.backgroundColor = NSColor(red: 0.82, green: 0.74, blue: 0.64, alpha: 1)
                window.appearance = NSAppearance(named: .aqua)
            }
        }
    }
}

struct RowLabel: View {
    var title: String
    var detail: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(2.2)
                .foregroundStyle(KeySaxTheme.muted(scheme))
            Text(detail)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(KeySaxTheme.muted(scheme).opacity(0.75))
            Spacer()
        }
    }
}
