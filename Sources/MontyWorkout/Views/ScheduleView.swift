import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var history: HistoryStore
    @EnvironmentObject private var session: WorkoutSession
    @State private var expanded: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Schedule")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("6 days on, Sunday off · warm-up, training, yoga, cardio")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
                    .padding(.bottom, 4)

                ForEach(Array(Schedule.all.enumerated()), id: \.element.id) { i, workout in
                    dayCard(workout).entrance(Double(i) * 0.04)
                }
            }
            .padding(28)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func dayCard(_ workout: Workout) -> some View {
        let isOpen = expanded == workout.id

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(Theme.springSnappy) {
                    expanded = isOpen ? nil : workout.id
                }
            } label: {
                HStack(spacing: 12) {
                    Text(weekdayName(workout.weekday))
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(Theme.faint)
                        .frame(width: 78, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Text("\(workout.exerciseCount) exercises · ~\(workout.estimatedMinutes) min")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.faint)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.dim)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(spacing: 0) {
                    Divider().overlay(Theme.surfaceHi).padding(.vertical, 12)
                    ForEach(Array(workout.steps.enumerated()), id: \.element.id) { idx, step in
                        HoverRow {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 10) {
                                    Text(step.name)
                                        .font(.system(size: 13, weight: .medium))
                                    Spacer()
                                    Text(step.targetLabel)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Theme.dim)
                                    KindBadge(kind: step.kind)
                                }
                                Text(step.cue)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.faint)
                            }
                            .padding(.vertical, 7)
                        }
                        if idx < workout.steps.count - 1 {
                            Divider().overlay(Theme.surfaceHi.opacity(0.4))
                        }
                    }

                    PrimaryButton(title: "Start \(workout.title)", systemImage: "play.fill") {
                        session.start(workout, history: history)
                    }
                    .padding(.top, 14)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .card(18)
    }

    private func weekdayName(_ weekday: Int) -> String {
        let names = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return names[safe: weekday] ?? ""
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
