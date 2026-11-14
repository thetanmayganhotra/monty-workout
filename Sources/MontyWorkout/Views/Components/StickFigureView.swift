import SwiftUI

/// Draws one stick-figure pose. All limb maths lives in StickFigure.swift.
struct StickFigureView: View {
    let pose: Pose
    let guide: Guide
    var lineWidth: Double = 0.03
    var margin: Double = 0.12

    var body: some View {
        Canvas { ctx, size in
            let fit = FigureFit(box: guide.box, size: size, margin: margin)
            let d = drawing(for: pose, anchor: guide.anchor)
            let lw = CGFloat(lineWidth * fit.scale)

            // Floor (and wall, when the pose needs one).
            let gy = fit.map(CGPoint(x: 0, y: 0)).y
            var floor = Path()
            floor.move(to: CGPoint(x: 6, y: gy))
            floor.addLine(to: CGPoint(x: size.width - 6, y: gy))
            ctx.stroke(floor, with: .color(Theme.faint.opacity(0.7)), lineWidth: 1.5)

            if case .wall(let wx) = guide.scene {
                var wall = Path()
                wall.move(to: fit.map(CGPoint(x: wx, y: guide.box.minY)))
                wall.addLine(to: fit.map(CGPoint(x: wx, y: 0)))
                ctx.stroke(wall, with: .color(Theme.faint), lineWidth: 2)
            }

            for l in d.lines {
                var p = Path()
                p.move(to: fit.map(l.a))
                p.addLine(to: fit.map(l.b))
                ctx.stroke(p, with: .color(l.far ? Theme.dim : Theme.text),
                           style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
            }

            let hc = fit.map(d.head)
            let hr = CGFloat(Bones.headR * fit.scale)
            let head = Path(ellipseIn: CGRect(x: hc.x - hr, y: hc.y - hr, width: hr * 2, height: hr * 2))
            ctx.fill(head, with: .color(Theme.surface))
            ctx.stroke(head, with: .color(Theme.text), lineWidth: lw)

            for pr in d.props {
                let c = fit.map(pr.center)
                let r = CGFloat((pr.kind == .kettlebell ? 0.055 : 0.04) * fit.scale)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                         with: .color(Theme.accent))
            }
        }
    }
}

/// Shared clock so the big animated figure and the highlighted step stay in sync.
enum GuideClock {
    static let hold = 1.1, move = 0.9

    static func state(_ t: TimeInterval, count n: Int) -> (from: Int, to: Int, ease: Double, active: Int) {
        guard n > 1 else { return (0, 0, 0, 0) }
        let cycle = hold + move
        let pos = t / cycle
        let base = Int(floor(pos))
        let i = ((base % n) + n) % n
        let f = (pos - floor(pos)) * cycle
        if f < hold { return (i, i, 0, i) }
        let m = (f - hold) / move
        let e = m * m * (3 - 2 * m)
        let next = (i + 1) % n
        return (i, next, e, e > 0.5 ? next : i)
    }
}

/// The stick figure moving through the steps on a loop.
struct AnimatedGuideFigure: View {
    let guide: Guide

    var body: some View {
        TimelineView(.animation) { tl in
            let st = GuideClock.state(tl.date.timeIntervalSinceReferenceDate, count: guide.steps.count)
            let pose = guide.steps[st.from].pose.lerp(to: guide.steps[st.to].pose, st.ease)
            StickFigureView(pose: pose, guide: guide)
        }
    }
}

/// "Kaise karna hai" — animated figure plus each step as text with its own little figure.
struct GuidePanel: View {
    let guide: Guide
    var onSpeak: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Kaise karna hai")
                Spacer()
                Button(action: onSpeak) {
                    Label("Sunao", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.accent)
                .help("Steps dobara bolke sunao")
            }

            AnimatedGuideFigure(guide: guide)
                .frame(height: 170)
                .background(Theme.bg.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            TimelineView(.periodic(from: .now, by: 0.2)) { tl in
                let active = GuideClock.state(tl.date.timeIntervalSinceReferenceDate,
                                              count: guide.steps.count).active
                VStack(spacing: 8) {
                    ForEach(Array(guide.steps.enumerated()), id: \.offset) { i, step in
                        GuideStepRow(index: i, step: step, guide: guide, active: i == active)
                    }
                }
            }
        }
        .card(16)
    }
}

private struct GuideStepRow: View {
    let index: Int
    let step: GuideStep
    let guide: Guide
    let active: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            StickFigureView(pose: step.pose, guide: guide, lineWidth: 0.045, margin: 0.05)
                .frame(width: 76, height: 76)
                .background(Theme.bg.opacity(0.6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("STEP \(index + 1)")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(active ? Theme.accent : Theme.faint)
                Text(step.text)
                    .font(.system(size: 12))
                    .foregroundStyle(active ? Theme.text : Theme.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(active ? Theme.surfaceHi : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(active ? Theme.accent.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.25), value: active)
    }
}

/// Paced-breathing orb: grows on the inhale, holds, shrinks on the exhale.
struct BreathOrb: View {
    let info: BreathInfo?
    var height: CGFloat = 260

    var body: some View {
        let scale = info?.targetScale ?? 0.55
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Theme.surfaceHi, lineWidth: 1)
                )

            Circle()
                .strokeBorder(Theme.accent.opacity(0.22), lineWidth: 2)
                .frame(width: height * 0.78, height: height * 0.78)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.accent.opacity(0.55), Theme.accent.opacity(0.14)],
                        center: .center, startRadius: 4, endRadius: height * 0.4
                    )
                )
                .frame(width: height * 0.78, height: height * 0.78)
                .scaleEffect(scale)
                .animation(.linear(duration: 1), value: scale)

            VStack(spacing: 2) {
                Text((info?.label ?? "Ready").uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.text.opacity(0.85))
                if let info {
                    Text("\(info.count)")
                        .font(.system(size: 54, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text("round \(info.round) of \(info.rounds)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.dim)
                }
            }
        }
        .frame(height: height)
    }
}
