import Foundation
import Combine

/// One completed (or abandoned) run of a workout.
struct SessionRecord: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var date: Date                 // when the session started
    var workoutID: String
    var workoutTitle: String
    var completed: Bool            // reached the end vs. ended early
    var workSeconds: Int
    var restSeconds: Int
    var setsCompleted: Int
    var stepsCompleted: Int
    var stepsTotal: Int

    var totalSeconds: Int { workSeconds + restSeconds }
}

/// Per-day status used by the calendar grid.
enum DayStatus { case done, partial, missed, rest, today, upcoming, blank }

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var records: [SessionRecord] = []

    private let calendar = Calendar.current
    private let fileURL: URL

    init() {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MontyWorkout", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        fileURL = base.appendingPathComponent("history.json")
        load()
    }

    var storageDirectory: URL { fileURL.deletingLastPathComponent() }

    // MARK: Mutations

    func add(_ record: SessionRecord) {
        records.append(record)
        records.sort { $0.date > $1.date }
        save()
    }

    func resetAll() {
        records = []
        save()
    }

    // MARK: Queries

    /// Best record for a given calendar day — a completed one wins over a partial.
    func record(on day: Date) -> SessionRecord? {
        let matches = records.filter { calendar.isDate($0.date, inSameDayAs: day) }
        return matches.first(where: { $0.completed }) ?? matches.first
    }

    func status(for day: Date, referenceDate: Date = Date()) -> DayStatus {
        let weekday = calendar.component(.weekday, from: day)
        let startOfDay = calendar.startOfDay(for: day)
        let startOfToday = calendar.startOfDay(for: referenceDate)

        if let rec = record(on: day) {
            return rec.completed ? .done : .partial
        }
        if calendar.isDate(day, inSameDayAs: referenceDate) { return .today }
        if !Schedule.isTrainingDay(weekday) { return .rest }
        if startOfDay > startOfToday { return .upcoming }

        // Past training day with no record — only count it as missed once history has begun.
        if let first = records.map(\.date).min(),
           startOfDay >= calendar.startOfDay(for: first) {
            return .missed
        }
        return .blank
    }

    /// Consecutive training days up to today with a completed workout. Rest days don't break it.
    func currentStreak(referenceDate: Date = Date()) -> Int {
        var streak = 0
        var cursor = calendar.startOfDay(for: referenceDate)
        // If today is a training day not yet done, the streak is measured up to yesterday.
        for _ in 0..<400 {
            let weekday = calendar.component(.weekday, from: cursor)
            if Schedule.isTrainingDay(weekday) {
                if let rec = record(on: cursor), rec.completed {
                    streak += 1
                } else if !calendar.isDate(cursor, inSameDayAs: referenceDate) {
                    break
                }
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    func bestStreak() -> Int {
        guard !records.isEmpty else { return 0 }
        let done = Set(records.filter(\.completed).map { calendar.startOfDay(for: $0.date) })
        guard let earliest = done.min() else { return 0 }
        var best = 0, run = 0
        var cursor = earliest
        let end = calendar.startOfDay(for: Date())
        while cursor <= end {
            let weekday = calendar.component(.weekday, from: cursor)
            if Schedule.isTrainingDay(weekday) {
                if done.contains(cursor) { run += 1; best = max(best, run) }
                else { run = 0 }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return best
    }

    /// Completed training days in the current week (Mon-anchored) and the target (6).
    func weekProgress(referenceDate: Date = Date()) -> (done: Int, target: Int) {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        guard let interval = cal.dateInterval(of: .weekOfYear, for: referenceDate) else { return (0, 6) }
        let done = records
            .filter { $0.completed && interval.contains($0.date) }
            .map { cal.startOfDay(for: $0.date) }
        return (Set(done).count, 6)
    }

    var totalWorkouts: Int { records.filter(\.completed).count }
    var totalSeconds: Int { records.reduce(0) { $0 + $1.totalSeconds } }
    var totalRestSeconds: Int { records.reduce(0) { $0 + $1.restSeconds } }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([SessionRecord].self, from: data) {
            records = decoded.sorted { $0.date > $1.date }
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(records) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
