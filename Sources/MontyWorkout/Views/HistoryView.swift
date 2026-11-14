import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var history: HistoryStore

    private let weeksBack = 10

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("History")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .entrance()

                statsRow.entrance(0.03)
                calendar.entrance(0.06)
                legend.entrance(0.06)

                if !history.records.isEmpty {
                    recent.entrance(0.09)
                }
            }
            .padding(28)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(history.currentStreak())", label: "Streak", tint: Theme.accent)
            StatTile(value: "\(history.bestStreak())", label: "Best")
            StatTile(value: "\(history.totalWorkouts)", label: "Workouts")
            StatTile(value: hoursLabel(history.totalSeconds), label: "Total time")
        }
    }

    // MARK: Calendar grid

    private var calendar: some View {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let today = Date()
        let thisWeekStart = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let firstWeekStart = cal.date(byAdding: .weekOfYear, value: -(weeksBack - 1), to: thisWeekStart) ?? today

        return VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Last \(weeksBack) weeks")

            HStack(alignment: .top, spacing: 6) {
                VStack(spacing: 6) {
                    ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { d in
                        Text(d)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Theme.faint)
                            .frame(width: 14, height: 18)
                    }
                }

                ForEach(0..<weeksBack, id: \.self) { w in
                    let weekStart = cal.date(byAdding: .weekOfYear, value: w, to: firstWeekStart) ?? today
                    VStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { d in
                            let day = cal.date(byAdding: .day, value: d, to: weekStart) ?? today
                            cell(for: day, today: today)
                        }
                    }
                }
                Spacer()
            }
        }
        .card(18)
    }

    private func cell(for day: Date, today: Date) -> some View {
        let status = day > today ? DayStatus.upcoming : history.status(for: day, referenceDate: today)
        return CalendarCell(color: color(for: status), highlighted: status == .today)
            .help(day.formatted(.dateTime.month().day()))
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(Theme.good, "Completed")
            legendItem(Theme.accent, "Partial")
            legendItem(Theme.miss.opacity(0.85), "Missed")
            legendItem(Theme.surfaceHi, "Rest / upcoming")
        }
        .padding(.horizontal, 4)
    }

    private func legendItem(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3).fill(c).frame(width: 10, height: 10)
            Text(t).font(.system(size: 11)).foregroundStyle(Theme.dim)
        }
    }

    // MARK: Recent list

    private var recent: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Recent sessions")
            VStack(spacing: 0) {
                ForEach(history.records.prefix(12)) { rec in
                    HoverRow {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(rec.completed ? Theme.good : Theme.accent)
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.workoutTitle)
                                    .font(.system(size: 13, weight: .medium))
                                Text(rec.date.formatted(.dateTime.weekday().month().day().hour().minute()))
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.faint)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(clock(rec.totalSeconds))
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                Text("\(clock(rec.restSeconds)) rest")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.faint)
                            }
                            Text(rec.completed ? "complete" : "partial")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(rec.completed ? Theme.good : Theme.dim)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.vertical, 9)
                    }
                    if rec.id != history.records.prefix(12).last?.id {
                        Divider().overlay(Theme.surfaceHi.opacity(0.5))
                    }
                }
            }
            .card(16)
        }
    }

    // MARK: Helpers

    private func hoursLabel(_ seconds: Int) -> String {
        if seconds < 3600 { return "\(seconds / 60)m" }
        let h = Double(seconds) / 3600
        return String(format: "%.1fh", h)
    }

    private func color(for status: DayStatus) -> Color {
        switch status {
        case .done: Theme.good
        case .partial: Theme.accent
        case .missed: Theme.miss.opacity(0.85)
        case .today: Theme.surfaceHi
        case .rest, .upcoming, .blank: Theme.surface
        }
    }
}

/// One day in the streak calendar — grows slightly on hover.
private struct CalendarCell: View {
    let color: Color
    let highlighted: Bool
    @State private var hovering = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(color)
            .frame(width: 18, height: 18)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Theme.text.opacity(highlighted ? 0.9 : 0), lineWidth: 1.5)
            )
            .scaleEffect(hovering ? 1.25 : 1)
            .shadow(color: hovering ? color.opacity(0.6) : .clear, radius: 4)
            .onHover { hovering = $0 }
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: hovering)
    }
}
