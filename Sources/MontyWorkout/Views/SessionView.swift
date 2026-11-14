import SwiftUI

struct SessionView: View {
    @EnvironmentObject private var session: WorkoutSession
    @State private var confirmEnd = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if case .done(let summary) = session.phase {
                SummaryView(summary: summary) { session.dismiss() }
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                activeBody
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(Theme.springSmooth, value: isDone)
    }

    private var isDone: Bool { if case .done = session.phase { true } else { false } }

    // MARK: Active

    private var activeBody: some View {
        VStack(spacing: 0) {
            topBar

            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 22) {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            centerStage
                                .id(session.index)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.96)).combined(with: .offset(y: 6)),
                                    removal: .opacity.combined(with: .scale(scale: 0.96))
                                ))
                            Spacer(minLength: 0)
                            controls
                            footerStats
                        }
                        .frame(minWidth: 380, maxWidth: 460)

                        if let e = session.guideEffort, let guide = GuideBank.guide(e.guideKey ?? e.cueKey) {
                            GuidePanel(guide: guide) { session.repeatInstructions() }
                                .id(e.guideKey ?? e.cueKey)
                                .transition(.opacity)
                                .frame(minWidth: 300, maxWidth: 380)
                        }
                    }
                    .animation(Theme.springSmooth, value: session.index)
                    .frame(minHeight: geo.size.height, alignment: .top)
                    .padding(.top, 8)
                }
            }
        }
        .padding(22)
        .frame(maxWidth: 940)
        .frame(maxWidth: .infinity)
    }

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                if let (n, total) = session.exercisePosition {
                    Text("Exercise \(n) of \(total)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.dim)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: n)
                }
                Spacer()
                Button {
                    withAnimation(Theme.springSnappy) { session.togglePause() }
                } label: {
                    Image(systemName: session.paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.text)
                }
                .buttonStyle(IconButtonStyle())

                Button("End") { confirmEnd = true }
                    .font(.system(size: 12, weight: .semibold))
                    .buttonStyle(PressableStyle())
                    .foregroundStyle(Theme.miss)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceHi).frame(height: 4)
                    Capsule().fill(Theme.accentGradient)
                        .frame(width: geo.size.width * session.overallProgress, height: 4)
                        .shadow(color: Theme.accent.opacity(0.5), radius: 4)
                        .animation(Theme.springSmooth, value: session.overallProgress)
                }
            }
            .frame(height: 4)
        }
        .confirmationDialog("End this workout?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("End workout", role: .destructive) { session.endEarly() }
            Button("Keep going", role: .cancel) { }
        } message: {
            Text("Your progress so far will be saved as a partial session.")
        }
    }

    // MARK: Center

    @ViewBuilder private var centerStage: some View {
        if let effort = session.currentEffort {
            VStack(spacing: 14) {
                Group {
                    if effort.breath != nil {
                        BreathOrb(info: session.breathInfo, height: 210)
                    } else {
                        GifView(
                            mediaID: effort.mediaID,
                            kind: effort.kind,
                            title: effort.title,
                            imageURLs: effort.imageURLs,
                            symbolOverride: effort.symbol,
                            height: 210
                        )
                        .id(effort.imageURLs?.first ?? effort.mediaID ?? effort.title)
                    }
                }
                .accentGlow(radius: 140, opacity: 0.14)

                VStack(spacing: 6) {
                    KindBadge(kind: effort.kind)
                    Text(effort.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text(effort.subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.dim)
                }

                targetReadout(effort)

                Text(session.caption ?? effort.cue)
                    .font(.system(size: 14))
                    .foregroundStyle(session.caption == nil ? Theme.dim : Theme.text)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.easeInOut(duration: 0.2), value: session.caption)
            }
        } else if let rest = session.currentRest {
            restStage(rest)
        }
    }

    @ViewBuilder private func targetReadout(_ effort: EffortSpec) -> some View {
        if effort.isTimed {
            let total = max(1, effort.seconds ?? 1)
            let remaining = session.phase == .working ? session.segmentRemaining : total
            ZStack {
                Ring(progress: 1 - Double(remaining) / Double(total))
                    .frame(width: 120, height: 120)
                VStack(spacing: 2) {
                    Text(clock(remaining))
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.snappy(duration: 0.3), value: remaining)
                    if effort.perSide {
                        Text("each side").font(.system(size: 10)).foregroundStyle(Theme.faint)
                    }
                }
            }
        } else {
            VStack(spacing: 0) {
                Text("\(effort.reps ?? 0)")
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                Text(effort.perSide ? "\(effort.repNoun) · each side" : effort.repNoun)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.dim)
            }
        }
    }

    private func restStage(_ rest: RestSpec) -> some View {
        VStack(spacing: 18) {
            Image(systemName: rest.reason == "Switch sides" ? "arrow.left.arrow.right" : "wind")
                .font(.system(size: 34, weight: .thin))
                .foregroundStyle(Theme.dim)
            Text(rest.reason.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Theme.faint)
            Text(clock(session.segmentRemaining))
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.accentGradient)
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy(duration: 0.3), value: session.segmentRemaining)
            if let next = rest.nextTitle {
                Text("Next: \(next)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.dim)
            }
            Text("Rest is tracked")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Theme.faint)
        }
    }

    // MARK: Controls

    @ViewBuilder private var controls: some View {
        VStack(spacing: 10) {
            switch session.phase {
            case .awaitingStart:
                PrimaryButton(title: "Start", systemImage: "play.fill") {
                    session.startEffort()
                }
            case .working:
                if let effort = session.currentEffort, effort.isTimed {
                    PrimaryButton(title: "Done", systemImage: "checkmark", tint: Theme.surfaceHi) {
                        session.completeCurrent()
                    }
                } else {
                    PrimaryButton(title: "Complete set", systemImage: "checkmark") {
                        session.completeCurrent()
                    }
                }
            case .resting:
                PrimaryButton(title: "Skip rest", systemImage: "forward.fill", tint: Theme.surfaceHi) {
                    session.skipRest()
                }
            case .idle, .done:
                EmptyView()
            }
        }
        .padding(.top, 8)
    }

    private var footerStats: some View {
        HStack(spacing: 22) {
            stat("Work", clock(session.workSeconds))
            stat("Rest", clock(session.restSeconds))
            stat("Total", clock(session.workSeconds + session.restSeconds))
            stat("Sets", "\(session.setsCompleted)")
        }
        .padding(.top, 10)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.3), value: value)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.faint)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Summary

struct SummaryView: View {
    let summary: SessionSummary
    var onClose: () -> Void

    @State private var iconIn = false
    @State private var statsIn = false

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill((summary.completed ? Theme.good : Theme.dim).opacity(0.14))
                    .frame(width: 92, height: 92)
                    .scaleEffect(iconIn ? 1 : 0.5)
                Image(systemName: summary.completed ? "checkmark.seal.fill" : "flag.checkered")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(summary.completed ? Theme.good : Theme.dim)
                    .scaleEffect(iconIn ? 1 : 0.4)
                    .opacity(iconIn ? 1 : 0)
            }

            VStack(spacing: 4) {
                Text(summary.completed ? "Workout complete" : "Session ended")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(summary.workoutTitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
            }
            .opacity(iconIn ? 1 : 0)

            HStack(spacing: 12) {
                StatTile(value: clock(summary.totalSeconds), label: "Total time")
                StatTile(value: clock(summary.workSeconds), label: "Working", tint: Theme.accent)
                StatTile(value: clock(summary.restSeconds), label: "Resting")
            }
            HStack(spacing: 12) {
                StatTile(value: "\(summary.setsCompleted)", label: "Sets done")
                StatTile(value: "\(summary.stepsCompleted)/\(summary.stepsTotal)", label: "Exercises")
            }
            .opacity(statsIn ? 1 : 0)
            .offset(y: statsIn ? 0 : 8)

            PrimaryButton(title: "Done", systemImage: "checkmark") { onClose() }
                .padding(.top, 4)
                .opacity(statsIn ? 1 : 0)
        }
        .padding(30)
        .frame(maxWidth: 460)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) { iconIn = true }
            withAnimation(Theme.springSmooth.delay(0.12)) { statsIn = true }
        }
    }
}
