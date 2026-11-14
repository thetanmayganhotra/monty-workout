import SwiftUI

/// Circular progress / countdown ring, with a soft glow and a spring catch-up.
struct Ring: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    var color: Color = Theme.accent

    var body: some View {
        ZStack {
            Circle().stroke(Theme.surfaceHi, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.0001, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.55), radius: 6)
                .animation(Theme.springSmooth, value: progress)
        }
    }
}

/// Big primary action button — gradient fill, hover brighten, press scale.
struct PrimaryButton: View {
    var title: String
    var systemImage: String?
    var tint: Color = Theme.accent
    var action: () -> Void

    @State private var hovering = false

    private var isSecondary: Bool { tint == Theme.surfaceHi }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(fill)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(hovering ? (isSecondary ? 0.16 : 0.28) : (isSecondary ? 0.08 : 0.14)), lineWidth: 1)
            )
            .shadow(color: isSecondary ? .clear : tint.opacity(hovering ? 0.45 : 0.26),
                    radius: hovering ? 20 : 13, x: 0, y: 7)
            .foregroundStyle(isSecondary ? Theme.text : Color(hex: 0x1A0E0B))
            .brightness(hovering ? 0.03 : 0)
        }
        .buttonStyle(PressableStyle())
        .onHover { hovering = $0 }
        .animation(Theme.springSnappy, value: hovering)
    }

    private var fill: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isSecondary ? AnyShapeStyle(tint) : AnyShapeStyle(Theme.accentGradient))
    }
}

/// Small labelled statistic, with the value rolling smoothly when it changes.
struct StatTile: View {
    var value: String
    var label: String
    var tint: Color = Theme.text

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.35), value: value)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.faint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(16)
    }
}

/// Section heading.
struct SectionTitle: View {
    var text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(Theme.faint)
    }
}

struct KindBadge: View {
    var kind: StepKind
    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.6)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(
                Capsule().fill(tint.opacity(0.18))
                    .overlay(Capsule().strokeBorder(tint.opacity(0.3), lineWidth: 1))
            )
            .foregroundStyle(tint)
    }
    private var label: String {
        switch kind {
        case .warmup: "WARM-UP"
        case .strength: "STRENGTH"
        case .hold: "HOLD"
        case .flow: "FLOW"
        case .cardio: "CARDIO"
        case .cooldown: "COOL-DOWN"
        }
    }
    private var tint: Color {
        switch kind {
        case .warmup: Theme.good
        case .strength: Theme.accent
        case .hold: Color(hex: 0xE7C15B)
        case .flow: Color(hex: 0x7FB0FF)
        case .cardio: Color(hex: 0xFF9F5C)
        case .cooldown: Theme.dim
        }
    }
}

/// A list row that highlights softly on hover — used in Today's exercise list,
/// History's recent sessions, and Schedule's expanded steps.
struct HoverRow<Content: View>: View {
    @ViewBuilder var content: Content
    var corner: CGFloat = 10
    @State private var hovering = false

    var body: some View {
        content
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(hovering ? Theme.surfaceHi.opacity(0.6) : Color.clear)
            )
            .onHover { hovering = $0 }
            .animation(Theme.springSnappy, value: hovering)
    }
}

extension ExerciseStep {
    /// "5 × 8", "10 / side", "2 min", "45s × 2".
    var targetLabel: String {
        if let reps {
            let core = perSide ? "\(reps) / side" : "\(reps) \(repNoun == "reps" ? "reps" : repNoun)"
            return sets > 1 ? "\(sets) × \(perSide ? "\(reps)/side" : "\(reps)")" : core
        }
        if let secs = durationSeconds {
            let dur = secs % 60 == 0 ? "\(secs / 60) min" : "\(secs)s"
            return sets > 1 ? "\(dur) × \(sets)\(perSide ? " / side" : "")" : dur
        }
        return ""
    }
}
