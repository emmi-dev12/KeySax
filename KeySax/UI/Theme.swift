import SwiftUI

enum KeySaxTheme {
    static let brass = Color(red: 0.86, green: 0.68, blue: 0.36)
    static let brassDeep = Color(red: 0.48, green: 0.32, blue: 0.14)
    static let ivory = Color(red: 0.96, green: 0.93, blue: 0.86)
    static let ebony = Color(red: 0.10, green: 0.08, blue: 0.07)
    static let wood = Color(red: 0.42, green: 0.24, blue: 0.12)
    static let nickel = Color(red: 0.78, green: 0.76, blue: 0.70)
    static let stageDark = Color(red: 0.06, green: 0.045, blue: 0.04)
    static let stageMid = Color(red: 0.16, green: 0.10, blue: 0.07)

    static func stageGradient(scheme: ColorScheme) -> RadialGradient {
        if scheme == .dark {
            return RadialGradient(
                colors: [stageMid, stageDark],
                center: .center,
                startRadius: 40,
                endRadius: 640
            )
        }
        return RadialGradient(
            colors: [
                Color(red: 0.97, green: 0.94, blue: 0.88),
                Color(red: 0.82, green: 0.74, blue: 0.64)
            ],
            center: .center,
            startRadius: 40,
            endRadius: 640
        )
    }
}

struct GlassSurface<Content: View>: View {
    var corner: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(in: RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

struct RowLabel: View {
    var title: String
    var detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(2.2)
                .foregroundStyle(.secondary)
            Text(detail)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }
}
