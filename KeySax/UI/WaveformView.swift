import SwiftUI

struct WaveformView: View {
    var bins: [Float]
    var level: Float
    var accent: Color
    var compact: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { _ in
            Canvas { context, size in
                let count = max(1, bins.count)
                let gap: CGFloat = compact ? 2 : 3
                let w = max(2, (size.width - gap * CGFloat(count - 1)) / CGFloat(count))
                for (i, bin) in bins.enumerated() {
                    let h = max(2, CGFloat(bin) * size.height)
                    let x = CGFloat(i) * (w + gap)
                    let y = (size.height - h) / 2
                    let rect = CGRect(x: x, y: y, width: w, height: h)
                    let path = RoundedRectangle(cornerRadius: w / 2, style: .continuous).path(in: rect)
                    let t = Double(i) / Double(count)
                    context.fill(path, with: .color(accent.opacity(0.35 + 0.65 * (1 - t * 0.4))))
                }
                if level > 0.02 {
                    let breath = CGRect(
                        x: 0,
                        y: size.height * 0.5 - 0.6,
                        width: size.width * CGFloat(min(1, level * 1.4)),
                        height: 1.2
                    )
                    context.fill(Rectangle().path(in: breath), with: .color(accent.opacity(0.55)))
                }
            }
        }
        .frame(height: compact ? 28 : 42)
        .accessibilityLabel("Live spectrum")
        .accessibilityValue("Level \(Int(level * 100)) percent")
    }
}
