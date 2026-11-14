import SwiftUI

/// One dark palette, one warm accent. Everything else is spacing, type, and motion.
enum Theme {
    static let bg         = Color(hex: 0x0B0B0E)
    static let surface    = Color(hex: 0x18181D)
    static let surfaceHi  = Color(hex: 0x232329)
    static let surfaceHi2 = Color(hex: 0x2D2D34)
    static let text       = Color(hex: 0xF5F5F7)
    static let dim        = Color(hex: 0x96969F)
    static let faint      = Color(hex: 0x616168)
    static let accent     = Color(hex: 0xFF7A5C)
    static let accent2    = Color(hex: 0xFFB36B)
    static let good       = Color(hex: 0x54D08A)
    static let miss       = Color(hex: 0xE0574A)

    static let corner: CGFloat = 20

    static let accentGradient = LinearGradient(
        colors: [accent2, accent], startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// Quick, responsive — button presses, tab switches, hover states.
    static let springSnappy = Animation.spring(response: 0.32, dampingFraction: 0.72)
    /// Slower, softer — page entrances, exercise-to-exercise transitions.
    static let springSmooth = Animation.spring(response: 0.5, dampingFraction: 0.86)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Card

extension View {
    /// Standard elevated card container used across the app: a soft fill, a
    /// hairline top highlight, and a gentle drop shadow to lift it off the background.
    func card(_ padding: CGFloat = 20, corner: CGFloat = Theme.corner) -> some View {
        self.padding(padding)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.09), Color.white.opacity(0.015)],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.30), radius: 14, x: 0, y: 7)
            )
    }

    /// A faint radial accent glow, meant to sit behind a card or media frame for depth.
    func accentGlow(_ color: Color = Theme.accent, radius: CGFloat = 120, opacity: Double = 0.16) -> some View {
        background(
            Circle()
                .fill(color)
                .opacity(opacity)
                .blur(radius: radius / 2)
                .frame(width: radius * 1.6, height: radius * 1.6)
        )
    }
}

// MARK: - Button styles

/// Scales down slightly on press, with a matching spring back — used everywhere a
/// button needs to feel physically pressed rather than just clicked.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Small circular icon buttons (pause, end, etc.) — hover brightens, press scales.
struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 28
    @State private var hovering = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(hovering ? Theme.surfaceHi2 : Theme.surfaceHi, in: Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(Theme.springSnappy, value: hovering)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
            .onHover { hovering = $0 }
    }
}

// MARK: - Entrance animation

/// A gentle fade + rise used to bring cards and rows to life when a page appears,
/// instead of them just popping in.
private struct Entrance: ViewModifier {
    var delay: Double
    var distance: CGFloat = 10
    @State private var shown = false
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : distance)
            .onAppear {
                withAnimation(Theme.springSmooth.delay(delay)) { shown = true }
            }
    }
}

extension View {
    func entrance(_ delay: Double = 0) -> some View { modifier(Entrance(delay: delay)) }
}

// MARK: - Formatting

/// Formats a raw second count as m:ss (or h:mm:ss past an hour).
func clock(_ seconds: Int) -> String {
    let s = max(0, seconds)
    let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec)
                 : String(format: "%d:%02d", m, sec)
}

/// Spoken-word phrase for a duration, e.g. 90 -> "1 minute 30 second".
func spokenDuration(_ seconds: Int) -> String {
    let m = seconds / 60, s = seconds % 60
    switch (m, s) {
    case (0, _):  return "\(s) second"
    case (_, 0):  return "\(m) minute"
    default:      return "\(m) minute \(s) second"
    }
}
