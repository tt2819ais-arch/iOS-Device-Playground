import SwiftUI

/// Liquid glass-style background with soft highlights.
/// Uses `.ultraThinMaterial` for broad iOS 17 compatibility plus a tinted
/// gradient overlay and inner highlight to mimic the new "Liquid Glass" look.
struct LiquidGlassBackground: View {
    var cornerRadius: CGFloat = 22
    var tint: Color = .accentColor
    var intensity: Double = 0.18

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(intensity),
                            tint.opacity(intensity * 0.4),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.55),
                            .white.opacity(0.05),
                            .white.opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 22, tint: Color = .accentColor) -> some View {
        background(LiquidGlassBackground(cornerRadius: cornerRadius, tint: tint))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Subtle animated gradient backdrop for the whole app.
struct AnimatedAuroraBackground: View {
    @State private var phase: CGFloat = 0
    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let p = CGFloat(sin(t / 6))
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.10, blue: 0.20),
                        Color(red: 0.20, green: 0.10, blue: 0.30),
                        Color(red: 0.05, green: 0.20, blue: 0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [Color.purple.opacity(0.45), .clear],
                    center: UnitPoint(x: 0.2 + 0.15 * p, y: 0.25),
                    startRadius: 20,
                    endRadius: 320
                )

                RadialGradient(
                    colors: [Color.cyan.opacity(0.35), .clear],
                    center: UnitPoint(x: 0.85 - 0.15 * p, y: 0.8),
                    startRadius: 20,
                    endRadius: 360
                )

                RadialGradient(
                    colors: [Color.pink.opacity(0.25), .clear],
                    center: UnitPoint(x: 0.6, y: 0.5 + 0.1 * p),
                    startRadius: 30,
                    endRadius: 300
                )
            }
            .ignoresSafeArea()
        }
    }
}

/// Light-mode-friendly version that adapts.
struct AdaptiveBackground: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Group {
            if scheme == .dark {
                AnimatedAuroraBackground()
            } else {
                TimelineView(.animation) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let p = CGFloat(sin(t / 6))
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.96, blue: 1.0),
                                Color(red: 0.92, green: 0.95, blue: 0.98),
                                Color(red: 0.96, green: 0.92, blue: 0.98)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        RadialGradient(colors: [Color.blue.opacity(0.18), .clear],
                                       center: UnitPoint(x: 0.2 + 0.1 * p, y: 0.25),
                                       startRadius: 20, endRadius: 320)
                        RadialGradient(colors: [Color.pink.opacity(0.15), .clear],
                                       center: UnitPoint(x: 0.85 - 0.1 * p, y: 0.8),
                                       startRadius: 20, endRadius: 320)
                    }
                    .ignoresSafeArea()
                }
            }
        }
    }
}
