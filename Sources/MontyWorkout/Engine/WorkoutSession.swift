import Foundation
import Combine

// MARK: - Plan segments

/// One thing you actively do. Always begins paused, waiting for **Start**.
struct EffortSpec: Identifiable, Equatable {
    let id: String
    let stepID: String
    let stepIndex: Int          // 0-based index into workout.steps
    let title: String
    let subtitle: String        // "Set 2 of 5", "Left side", "Hold"
    let kind: StepKind
    let reps: Int?              // rep target; nil => timed
    let repNoun: String
    let perSide: Bool
    let seconds: Int?          // timed target; nil => rep-based
    let cue: String
    let midCue: String?
    let cueKey: String?
    let note: String?
    let mediaID: String?
    let imageURLs: [String]?
    let symbol: String?
    let guideKey: String?
    let script: [ScriptLine]?
    let breath: BreathPattern?
    let autoStart: Bool
    /// First effort of its step — the one that gets the full spoken instructions.
    let introFull: Bool

    var isTimed: Bool { seconds != nil }
    var isGuided: Bool { script != nil || breath != nil }
}

/// Where we are inside a paced-breathing exercise.
struct BreathInfo: Equatable {
    let round: Int
    let rounds: Int
    let label: String
    let kind: BreathPhase.Kind
    let count: Int            // 1-based second within the phase
    let phaseSeconds: Int
    let targetScale: Double   // orb size at the end of this second (0.55 … 1.0)
}

/// An automatically-counted rest gap. The clock keeps running here.
struct RestSpec: Identifiable, Equatable {
    let id = UUID()
    let seconds: Int
    let reason: String          // "Rest", "Switch sides", "Next up"
    let nextTitle: String?
}

enum Segment: Identifiable, Equatable {
    case effort(EffortSpec)
    case rest(RestSpec)

    var id: String {
        switch self {
        case .effort(let e): return "e-\(e.id)"
        case .rest(let r):   return "r-\(r.id.uuidString)"
        }
    }
}

// MARK: - Summary

struct SessionSummary: Equatable {
    let workoutTitle: String
    let completed: Bool
    let workSeconds: Int
    let restSeconds: Int
    let setsCompleted: Int
    let stepsCompleted: Int
    let stepsTotal: Int

    var totalSeconds: Int { workSeconds + restSeconds }
}

// MARK: - Session

@MainActor
final class WorkoutSession: ObservableObject {

    enum Phase: Equatable {
        case idle
        case awaitingStart      // effort on screen, not started — clock not counting
        case working            // effort in progress
        case resting            // auto countdown, clock counting
        case done(SessionSummary)
    }

    @Published private(set) var isRunning = false
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var index = 0
    @Published private(set) var segmentRemaining = 0     // timed work / rest countdown
    @Published private(set) var workSeconds = 0
    @Published private(set) var restSeconds = 0
    @Published private(set) var setsCompleted = 0
    @Published var paused = false
    @Published private(set) var caption: String?
    @Published private(set) var breathInfo: BreathInfo?
    @Published private(set) var elapsedInSegment = 0

    private(set) var workout: Workout?
    private var plan: [Segment] = []
    private var startedAt = Date()
    private var lastSegmentIndexForStep: [Int: Int] = [:]
    private weak var history: HistoryStore?
    private var ticker: Timer?

    // MARK: Derived

    var planCount: Int { plan.count }

    var overallProgress: Double {
        guard !plan.isEmpty else { return 0 }
        return min(1, Double(index) / Double(plan.count))
    }

    var currentEffort: EffortSpec? {
        guard plan.indices.contains(index), case .effort(let e) = plan[index] else { return nil }
        return e
    }

    var currentRest: RestSpec? {
        guard plan.indices.contains(index), case .rest(let r) = plan[index] else { return nil }
        return r
    }

    /// The next effort after the current segment (previewed while resting).
    var upcomingEffort: EffortSpec? {
        guard index + 1 < plan.count else { return nil }
        for i in (index + 1)..<plan.count {
            if case .effort(let e) = plan[i] { return e }
        }
        return nil
    }

    /// The effort whose how-to guide is on screen — the next one while resting.
    var guideEffort: EffortSpec? { currentEffort ?? upcomingEffort }

    /// (currentExerciseNumber, totalExercises) for the header.
    var exercisePosition: (Int, Int)? {
        guard let w = workout else { return nil }
        let ref = currentEffort ?? lookBackEffort()
        guard let e = ref else { return nil }
        return (e.stepIndex + 1, w.steps.count)
    }

    private func lookBackEffort() -> EffortSpec? {
        var i = min(index, plan.count - 1)
        while i >= 0 {
            if case .effort(let e) = plan[i] { return e }
            i -= 1
        }
        return nil
    }

    // MARK: Lifecycle

    func start(_ workout: Workout, history: HistoryStore) {
        self.workout = workout
        self.history = history
        self.plan = Self.buildPlan(workout)
        self.lastSegmentIndexForStep = Self.lastSegmentIndexPerStep(plan)
        self.startedAt = Date()
        index = 0
        workSeconds = 0
        restSeconds = 0
        setsCompleted = 0
        paused = false
        isRunning = true
        startTicker()
        enter(0)
    }

    func dismiss() {
        stopTicker()
        Announcer.shared.stop()
        isRunning = false
        phase = .idle
        plan = []
        workout = nil
        index = 0
        caption = nil
        breathInfo = nil
    }

    // MARK: User actions

    /// Begin the effort currently on screen. Nothing counts until this is tapped.
    func startEffort() {
        guard case .awaitingStart = phase, let e = currentEffort else { return }
        begin(e, spokenStart: true)
    }

    private func begin(_ e: EffortSpec, spokenStart: Bool) {
        if let secs = e.seconds { segmentRemaining = secs }
        phase = .working
        elapsedInSegment = 0
        if e.isGuided {
            guidedTick(e, elapsed: 0)
        } else if spokenStart {
            if let secs = e.seconds {
                Announcer.shared.say(Phrases.duration(secs).text, interrupt: true)
                Announcer.shared.say(CueBank.start())
            } else {
                Announcer.shared.say(CueBank.start(), interrupt: true)
            }
        }
    }

    /// Read the step-by-step instructions again, on demand.
    func repeatInstructions() {
        guard let e = currentEffort, let g = GuideBank.guide(e.guideKey ?? e.cueKey) else { return }
        for (i, u) in Phrases.guideSteps(g, calm: e.isGuided).enumerated() {
            Announcer.shared.say(u.text, interrupt: i == 0, calm: u.calm)
        }
    }

    /// "Complete set" (reps) or "Done" (timed, finishing early).
    func completeCurrent() {
        guard case .working = phase else { return }
        setsCompleted += 1
        Announcer.shared.say(CueBank.setComplete(), interrupt: true)
        advance()
    }

    func skipRest() {
        guard case .resting = phase else { return }
        advance()
    }

    func togglePause() { paused.toggle() }

    func endEarly() { finish(completed: false) }

    // MARK: Engine

    private func enter(_ newIndex: Int) {
        guard newIndex < plan.count else { finish(completed: true); return }
        index = newIndex
        caption = nil
        breathInfo = nil
        elapsedInSegment = 0

        switch plan[newIndex] {
        case .effort(let e):
            phase = .awaitingStart
            segmentRemaining = e.seconds ?? 0
            if e.autoStart {
                begin(e, spokenStart: false)
            } else {
                announce(effort: e)
            }

        case .rest(let r):
            phase = .resting
            segmentRemaining = r.seconds
            switch r.reason {
            case "Switch sides":
                Announcer.shared.say(Phrases.switchSides, interrupt: false)
            default:
                // Queued (not interrupting) so a set-complete line can land first.
                Announcer.shared.say(CueBank.rest(), interrupt: false)
                if let next = r.nextTitle {
                    Announcer.shared.say(Phrases.nextPrefix)
                    Announcer.shared.say(next)
                }
            }
        }
    }

    private func advance() { enter(index + 1) }

    private func announce(effort e: EffortSpec) {
        var seq: [Utterance] = [Phrases.name(e)]
        if let sl = Phrases.setLine(e) { seq.append(sl) }
        if let t = Phrases.target(e) { seq.append(t) }
        if Announcer.shared.cues {
            let guide = GuideBank.guide(e.guideKey ?? e.cueKey)
            if e.introFull, let g = guide {
                // Guided (script/breath) steps narrate themselves — just set the scene.
                if e.isGuided { seq.append(Utterance(text: Phrases.guideStep(g, 0), calm: true)) }
                else { seq += Phrases.guideSteps(g, calm: false) }
                if let note = e.note { seq.append(Utterance(text: note, calm: e.isGuided)) }
            } else if !e.isGuided {
                let line = CueBank.line(forKey: e.cueKey, kind: e.kind)
                if !line.isEmpty { seq.append(Utterance(text: line, calm: false)) }
            }
        }
        for (i, u) in seq.enumerated() { Announcer.shared.say(u.text, interrupt: i == 0, calm: u.calm) }
    }

    // MARK: Guided narration

    private func guidedTick(_ e: EffortSpec, elapsed: Int) {
        if let lines = e.script {
            for l in lines where l.at == elapsed {
                caption = l.text
                Announcer.shared.say(l.text, interrupt: true, calm: true)
            }
        }
        if let b = e.breath { updateBreath(b, elapsed: elapsed) }
    }

    private func updateBreath(_ b: BreathPattern, elapsed: Int) {
        let cycle = b.cycleSeconds
        guard cycle > 0 else { return }
        let round = elapsed / cycle
        var t = elapsed % cycle
        for (i, p) in b.phases.enumerated() {
            if t < p.seconds {
                let end = Double(t + 1) / Double(p.seconds)
                let scale: Double
                switch p.kind {
                case .inhale: scale = 0.55 + 0.45 * end
                case .exhale: scale = 1.0 - 0.45 * end
                case .hold:
                    let prev = b.phases[(i + b.phases.count - 1) % b.phases.count].kind
                    scale = prev == .inhale ? 1.0 : 0.55
                }
                breathInfo = BreathInfo(round: round + 1, rounds: b.rounds, label: p.label,
                                        kind: p.kind, count: t + 1, phaseSeconds: p.seconds,
                                        targetScale: scale)
                if t == 0 {
                    let line = round == 0 ? (p.firstSay ?? p.say) : p.say
                    caption = line
                    Announcer.shared.say(line, interrupt: true, calm: true)
                }
                return
            }
            t -= p.seconds
        }
    }

    // MARK: Ticking

    private func startTicker() {
        stopTicker()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tick() {
        guard isRunning, !paused else { return }

        switch phase {
        case .working:
            guard let e = currentEffort else { return }
            workSeconds += 1
            if e.isTimed, let total = e.seconds {
                segmentRemaining -= 1
                elapsedInSegment = total - segmentRemaining
                if !e.isGuided, let mid = e.midCue, segmentRemaining == total / 2, total >= 60 {
                    Announcer.shared.say(mid)
                }
                if !e.isGuided, (1...3).contains(segmentRemaining) { Announcer.shared.tick() }
                if segmentRemaining <= 0 {
                    if e.isGuided { Announcer.shared.chime() }
                    else { Announcer.shared.say(Phrases.timeUp, interrupt: true) }
                    setsCompleted += 1
                    advance()
                } else if e.isGuided {
                    guidedTick(e, elapsed: elapsedInSegment)
                }
            }

        case .resting:
            restSeconds += 1
            segmentRemaining -= 1
            if segmentRemaining == 10 { Announcer.shared.say(Phrases.tenSeconds) }
            if (1...3).contains(segmentRemaining) { Announcer.shared.tick() }
            if segmentRemaining <= 0 {
                Announcer.shared.chime()
                advance()
            }

        default:
            break
        }
    }

    // MARK: Finish

    private func finish(completed: Bool) {
        stopTicker()
        Announcer.shared.stop()

        let stepsTotal = workout?.steps.count ?? 0
        let stepsCompleted = lastSegmentIndexForStep
            .filter { _, lastSeg in (completed ? plan.count : index) > lastSeg }
            .count

        let summary = SessionSummary(
            workoutTitle: workout?.title ?? "Workout",
            completed: completed,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            setsCompleted: setsCompleted,
            stepsCompleted: completed ? stepsTotal : stepsCompleted,
            stepsTotal: stepsTotal
        )

        if let w = workout {
            history?.add(SessionRecord(
                date: startedAt,
                workoutID: w.id,
                workoutTitle: w.title,
                completed: completed,
                workSeconds: workSeconds,
                restSeconds: restSeconds,
                setsCompleted: setsCompleted,
                stepsCompleted: summary.stepsCompleted,
                stepsTotal: stepsTotal
            ))
        }

        if completed {
            Announcer.shared.say(CueBank.finish(), interrupt: true)
        }
        phase = .done(summary)
    }

    // MARK: Plan construction

    static func buildPlan(_ w: Workout) -> [Segment] {
        var segs: [Segment] = []

        for (i, step) in w.steps.enumerated() {
            let setCount = max(1, step.sets)
            var first = true

            for s in 1...setCount {
                let setLabel: String = {
                    if step.sets > 1 { return "Set \(s) of \(step.sets)" }
                    if step.breath != nil || step.script != nil { return "Guided" }
                    if step.kind == .cardio { return "Steady" }
                    return step.durationSeconds != nil ? "Hold" : "Work"
                }()

                if let secs = step.durationSeconds {
                    if step.perSide {
                        let base = step.sets > 1 ? "Set \(s) · " : ""
                        segs.append(.effort(effort(step, i, subtitle: "\(base)Left side", seconds: secs, intro: &first)))
                        segs.append(.rest(RestSpec(seconds: 10, reason: "Switch sides", nextTitle: step.name)))
                        segs.append(.effort(effort(step, i, subtitle: "\(base)Right side", seconds: secs, intro: &first)))
                    } else {
                        segs.append(.effort(effort(step, i, subtitle: setLabel, seconds: secs, intro: &first)))
                    }
                } else {
                    segs.append(.effort(effort(step, i, subtitle: setLabel, reps: step.reps, intro: &first)))
                }

                if s < setCount, step.restAfterSetSeconds > 0 {
                    segs.append(.rest(RestSpec(seconds: step.restAfterSetSeconds,
                                              reason: "Rest", nextTitle: step.name)))
                }
            }

            if i < w.steps.count - 1, step.restAfterStepSeconds > 0 {
                segs.append(.rest(RestSpec(seconds: step.restAfterStepSeconds,
                                          reason: "Next up", nextTitle: w.steps[i + 1].name)))
            }
        }
        return segs
    }

    private static func effort(
        _ step: ExerciseStep, _ stepIndex: Int,
        subtitle: String, reps: Int? = nil, seconds: Int? = nil,
        intro: inout Bool
    ) -> EffortSpec {
        let isFirst = intro
        intro = false
        return EffortSpec(
            id: "\(step.id)-\(subtitle.replacingOccurrences(of: " ", with: "_"))",
            stepID: step.id,
            stepIndex: stepIndex,
            title: step.name,
            subtitle: subtitle,
            kind: step.kind,
            reps: reps,
            repNoun: step.repNoun,
            perSide: step.perSide,
            seconds: seconds,
            cue: step.cue,
            midCue: step.midCue,
            cueKey: step.cueKey,
            note: step.note,
            mediaID: step.mediaID,
            imageURLs: step.imageURLs,
            symbol: step.symbol,
            guideKey: step.guideKey,
            script: step.script,
            breath: step.breath,
            autoStart: step.autoStart,
            introFull: isFirst
        )
    }

    private static func lastSegmentIndexPerStep(_ plan: [Segment]) -> [Int: Int] {
        var map: [Int: Int] = [:]
        for (i, seg) in plan.enumerated() {
            if case .effort(let e) = seg { map[e.stepIndex] = i }
        }
        return map
    }
}
