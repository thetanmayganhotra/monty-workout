import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var history: HistoryStore
    @EnvironmentObject private var session: WorkoutSession

    private var today: Date { Date() }
    private var workout: Workout? { Schedule.today(today) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header.entrance()

                if let workout {
                    workoutCard(workout).entrance(0.04)
                } else {
                    restCard.entrance(0.04)
                }

                weekStrip.entrance(0.08)
            }
            .padding(28)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(today.formatted(.dateTime.weekday(.wide)))
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text(today.formatted(.dateTime.month(.wide).day().year()))
                .font(.system(size: 14))
                .foregroundStyle(Theme.dim)
        }
    }

    // MARK: Training day

    private func workoutCard(_ workout: Workout) -> some View {
        let doneToday = history.record(on: today)?.completed == true

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Circle().fill(Theme.accentGradient).frame(width: 7, height: 7)
                        Text(workout.title)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                    }
                    Text(workout.focus)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.dim)
                }
                Spacer()
                if doneToday {
                    Label("Done today", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.good)
                        .transition(.opacity.combined(with: .scale))
                }
            }

            HStack(spacing: 16) {
                metaChip("clock", "~\(workout.estimatedMinutes) min")
                metaChip("square.stack.3d.up", "\(workout.exerciseCount) exercises")
            }

            Divider().overlay(Theme.surfaceHi)

            VStack(spacing: 0) {
                ForEach(Array(workout.steps.enumerated()), id: \.element.id) { idx, step in
                    HoverRow {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Theme.surfaceHi).frame(width: 20, height: 20)
                                Text("\(idx + 1)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(Theme.dim)
                            }
                            Text(step.name)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                            Spacer(minLength: 12)
                            Text(step.targetLabel)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.dim)
                            KindBadge(kind: step.kind)
                        }
                        .padding(.vertical, 8)
                    }
                    if idx < workout.steps.count - 1 {
                        Divider().overlay(Theme.surfaceHi.opacity(0.5))
                    }
                }
            }

            PrimaryButton(
                title: doneToday ? "Run it again" : "Begin workout",
                systemImage: "play.fill"
            ) {
                session.start(workout, history: history)
            }
            .padding(.top, 4)
        }
        .card(22)
        .animation(Theme.springSnappy, value: doneToday)
    }

    // MARK: Rest day

    private var restCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Rest day")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text("Six days on, one off. Recover, walk, sleep well.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.dim)

            Menu {
                ForEach(Schedule.all) { w in
                    Button("\(w.title)") { session.start(w, history: history) }
                }
            } label: {
                Label("Train anyway", systemImage: "play.circle")
                    .font(.system(size: 13, weight: .semibold))
            }
            .menuStyle(.borderlessButton)
            .frame(width: 170)
            .padding(.top, 4)
        }
        .card(22)
    }

    // MARK: Week strip

    private var weekStrip: some View {
        let progress = history.weekProgress()
        var cal = Calendar.current
        cal.firstWeekday = 2
        let week = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: week) }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "This week")
                Spacer()
                Text("\(progress.done) / \(progress.target)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.dim)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: progress.done)
            }
            HStack(spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                    let status = history.status(for: day, referenceDate: today)
                    VStack(spacing: 6) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.faint)
                        ZStack {
                            if status == .today {
                                Circle()
                                    .stroke(Theme.accent.opacity(0.5), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                            }
                            Circle()
                                .fill(color(for: status))
                                .frame(width: 12, height: 12)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .entrance(Double(i) * 0.035)
                }
            }
        }
        .card(18)
    }

    private func metaChip(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11))
            Text(text).font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Theme.dim)
    }

    private func color(for status: DayStatus) -> Color {
        switch status {
        case .done: Theme.good
        case .partial: Theme.accent
        case .missed: Theme.miss.opacity(0.85)
        case .today: Theme.surfaceHi2
        case .rest, .upcoming, .blank: Theme.surfaceHi
        }
    }
}
