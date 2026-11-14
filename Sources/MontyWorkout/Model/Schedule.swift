import Foundation

// MARK: - Guided content types

/// A line spoken (and shown as a caption) `at` seconds into a timed step.
struct ScriptLine: Codable, Sendable, Equatable {
    var at: Int
    var text: String
}

struct BreathPhase: Codable, Sendable, Equatable {
    enum Kind: String, Codable, Sendable { case inhale, hold, exhale }
    var kind: Kind
    var label: String
    var seconds: Int
    /// Short line spoken at the start of every round.
    var say: String
    /// Longer line for the very first round only.
    var firstSay: String? = nil
}

struct BreathPattern: Codable, Sendable, Equatable {
    var phases: [BreathPhase]
    var rounds: Int

    var cycleSeconds: Int { phases.reduce(0) { $0 + $1.seconds } }
    var totalSeconds: Int { cycleSeconds * rounds }
}

// MARK: - Types

enum StepKind: String, Codable, Sendable {
    case warmup, strength, hold, flow, cardio, cooldown
}

/// A single line item in a workout (e.g. "Dumbbell overhead press — 3×10").
struct ExerciseStep: Identifiable, Codable, Sendable {
    var id: String
    var name: String
    var kind: StepKind

    var sets: Int
    /// Rep target per set. `nil` means the step is timed instead.
    var reps: Int?
    var repNoun: String = "reps"
    /// Duration per set for timed steps. `nil` means it is rep-based.
    var durationSeconds: Int?
    /// "each side" — reps show as "N / side"; timed holds run Left then Right.
    var perSide: Bool = false

    var restAfterSetSeconds: Int = 0
    var restAfterStepSeconds: Int = 45

    /// Short on-screen line (Hinglish).
    var cue: String
    /// Optional line spoken at the halfway point of a long timed step.
    var midCue: String?
    /// Key into `CueBank.pools` for the rotating spoken motivation lines.
    var cueKey: String?
    /// Key into `GuideBank` for the stick-figure step-by-step guide.
    var guideKey: String?
    /// free-exercise-db identifier for the looping follow-along animation.
    var mediaID: String?
    /// Direct image URL(s) for the follow-along (yoga poses etc.).
    var imageURLs: [String]?
    var note: String?
    /// SF Symbol for the placeholder card when there's no image.
    var symbol: String?
    /// Timed narration (flows, warrior sequences) — spoken at these offsets.
    var script: [ScriptLine]?
    /// Paced breathing, with an animated orb. Not used by the current routine
    /// (breathing/meditation now lives in a separate app) — kept so the engine
    /// and UI still support it if a day ever wants one again.
    var breath: BreathPattern?
    /// Starts immediately when reached (chained steps).
    var autoStart: Bool = false
}

struct Workout: Identifiable, Codable, Sendable {
    var id: String
    /// Calendar weekday: 1 = Sunday … 7 = Saturday.
    var weekday: Int
    var title: String
    var focus: String
    var estimatedMinutes: Int
    var steps: [ExerciseStep]

    var exerciseCount: Int { steps.count }
}

// MARK: - Follow-along imagery

private enum Img {
    static let sunSalutation = ["https://upload.wikimedia.org/wikipedia/commons/5/53/Suryanamaskar.gif"]
    static let warrior       = ["https://upload.wikimedia.org/wikipedia/commons/thumb/1/1d/Virabhadrasana_II_-_Warrior_II_Pose.jpg/960px-Virabhadrasana_II_-_Warrior_II_Pose.jpg"]
    static let halfMoon      = ["https://upload.wikimedia.org/wikipedia/commons/7/7b/Ardha-Chandrasana_Yoga-Asana_Nina-Mel.jpg"]
    static let camel         = ["https://upload.wikimedia.org/wikipedia/commons/b/b6/Ustrasana_Yoga-Asana_Nina-Mel.jpg"]
    static let childsPose    = ["https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Hatha_yoga_child_pose.jpg/960px-Hatha_yoga_child_pose.jpg"]
    static let backbend      = ["https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/Chakrasana_Yoga-Asana_Nina-Mel.jpg/960px-Chakrasana_Yoga-Asana_Nina-Mel.jpg"]
    static let boat          = ["https://upload.wikimedia.org/wikipedia/commons/3/3d/Paripurna-Navasana_Yoga-Asana_Nina-Mel.jpg"]
    static let handGripper   = ["https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Gripclosed.jpg/960px-Gripclosed.jpg"]
}

// MARK: - Builders

private func reps(
    _ id: String, _ name: String, _ kind: StepKind,
    sets: Int, reps: Int, noun: String = "reps", perSide: Bool = false,
    restSet: Int, restStep: Int = 45,
    cue: String, key: String? = nil, guide: String? = nil,
    media: String? = nil, images: [String]? = nil, note: String? = nil
) -> ExerciseStep {
    ExerciseStep(
        id: id, name: name, kind: kind, sets: sets, reps: reps, repNoun: noun,
        durationSeconds: nil, perSide: perSide,
        restAfterSetSeconds: restSet, restAfterStepSeconds: restStep,
        cue: cue, midCue: nil, cueKey: key, guideKey: guide,
        mediaID: media, imageURLs: images, note: note
    )
}

private func timed(
    _ id: String, _ name: String, _ kind: StepKind,
    sets: Int = 1, seconds: Int, perSide: Bool = false,
    restSet: Int = 15, restStep: Int = 30,
    cue: String, mid: String? = nil, key: String? = nil, guide: String? = nil,
    media: String? = nil, images: [String]? = nil, note: String? = nil,
    symbol: String? = nil, script: [ScriptLine]? = nil, auto: Bool = false
) -> ExerciseStep {
    ExerciseStep(
        id: id, name: name, kind: kind, sets: sets, reps: nil, repNoun: "reps",
        durationSeconds: seconds, perSide: perSide,
        restAfterSetSeconds: restSet, restAfterStepSeconds: restStep,
        cue: cue, midCue: mid, cueKey: key, guideKey: guide,
        mediaID: media, imageURLs: images, note: note, symbol: symbol,
        script: script, autoStart: auto
    )
}

private func L(_ at: Int, _ text: String) -> ScriptLine { ScriptLine(at: at, text: text) }

// MARK: - Scripts (timed narration for flows)

private enum Script {

    // Vinyasa: down dog → plank → chaturanga → up dog, 8 rounds in 6 minutes.
    static let vinyasa: [ScriptLine] = {
        let mids = [
            "Chaturanga — kohni pasliyon se chipki, control se neeche.",
            "Upward dog — seena aage, kandhe kaanon se door.",
            "Plank se neeche dheere — jhatka nahi.",
            "Hips upar-peeche, downward dog mein wapas. Saans ke saath.",
        ]
        var out: [ScriptLine] = []
        for r in 0..<8 {
            let t = r * 45
            let opener: String
            switch r {
            case 0: opener = "Vinyasa shuru. Downward dog se — hips upar, edi zameen ki taraf. Phir plank, chaturanga, upward dog. Aise aath baar."
            case 3: opener = "Round \(r + 1). Aadhe se zyada ho gaya. Saans mat rokna."
            case 7: opener = "Aakhri round. Sab kuch de do."
            default: opener = "Round \(r + 1). Downward dog, plank, chaturanga, upward dog."
            }
            out.append(L(t, opener))
            out.append(L(t + 24, mids[r % 4]))
        }
        out.append(L(352, "Bas. Ab child's pose."))
        return out
    }()

    // Warrior I ↔ II every 30 s, both sides.
    static func warriorFlow(perSide: Int) -> [ScriptLine] {
        var out: [ScriptLine] = []
        for side in 0..<2 {
            let base = side * perSide
            out.append(L(base, side == 0
                ? "Daayan pair aage. Warrior one — haath upar, kulhe saamne."
                : "Side badlo. Baayan pair aage. Warrior one."))
            var two = true
            var t = 30
            while t < perSide - 8 {
                out.append(L(base + t, two
                    ? "Warrior two — haath side mein, nazar aage wale haath par."
                    : "Warrior one — haath upar, seena khula."))
                two.toggle()
                t += 30
            }
        }
        return out
    }

    static let childsPose: [ScriptLine] = [
        L(0,  "Ghutno par baith jao. Aage jhuko, haath phailao, maatha zameen par."),
        L(28, "Saans peeth ki taraf bhejo — pasliyon ke andar."),
        L(62, "Har saans ke saath thoda aur dheela. Kandhe kaano se door."),
        L(96, "Poori peeth ko aaram do. Kuch nahi karna."),
    ]

    static let backbends3min: [ScriptLine] = [
        L(0,   "Pet ke bal let jao. Haath kandhon ke neeche. Seena khula, nazar thodi upar."),
        L(20,  "Haath dabao, seena upar. Kandhe kaanon se door. Gardan lambi."),
        L(70,  "Neeche aa jao, aaram. Ek do gehri saans."),
        L(100, "Dobara. Seena aage, kulhe zameen ke paas. Peeth ko mat todo."),
        L(150, "Dheere se neeche. Bas, ho gaya."),
    ]

    // Thursday: 3 reps × 30 s with rests, in 4 minutes.
    static let backbends4min: [ScriptLine] = [
        L(0,   "Pet ke bal let jao. Haath kandhon ke neeche. Pehle rep ke liye tayyar ho jao."),
        L(15,  "Rep ek. Haath dabao, seena upar. Tees second."),
        L(45,  "Neeche aa jao. Aaram. Gehri saans."),
        L(90,  "Rep do. Seena upar, kandhe kaanon se door."),
        L(120, "Neeche. Aaram karo."),
        L(165, "Aakhri rep. Poori koshish, par dard nahi."),
        L(195, "Neeche aa jao. Bas saans."),
    ]
}

// MARK: - The 6-day routine · warm-up, weights, yoga, cardio — 6 days a week
//
// No breathing / meditation block — that lives in a separate app now.

enum Schedule {
    static let all: [Workout] = [monday, tuesday, wednesday, thursday, friday, saturday]

    static func workout(forWeekday weekday: Int) -> Workout? {
        all.first { $0.weekday == weekday }
    }

    static func today(_ date: Date = Date(), calendar: Calendar = .current) -> Workout? {
        workout(forWeekday: calendar.component(.weekday, from: date))
    }

    /// Mon–Sat are training days; Sunday (weekday 1) is rest.
    static func isTrainingDay(_ weekday: Int) -> Bool { weekday != 1 }

    // MARK: shared step builders

    /// Always the first step of the day: mobility + a light stretch before touching weights.
    private static func warmup(_ id: String) -> ExerciseStep {
        timed(id, "Warm-up + stretch", .warmup,
              seconds: 150, restStep: 20,
              cue: "Kandhe aur kalaiyan ghumao, phir halki stretch. Training se pehle body jagao.",
              guide: "warmup", media: "Arm_Circles")
    }

    private static func treadmill(_ id: String, _ title: String, jog: Bool, note: String) -> ExerciseStep {
        timed(id, title, .cardio,
              seconds: 1200, restStep: 0,
              cue: "Bees minute. Ek pace pakdo jo tum nibha sako.",
              mid: "Aadha ho gaya. Das minute baaki.",
              key: "treadmill", guide: "run",
              media: jog ? "Jogging_Treadmill" : "Running_Treadmill",
              note: note)
    }

    private static func sun(_ id: String, rounds: Int, note: String? = nil) -> ExerciseStep {
        reps(id, "Sun salutations", .flow,
             sets: 1, reps: rounds, noun: "rounds", restSet: 0, restStep: 20,
             cue: "Saans ke saath flow karo. Andar — haath upar, bahar — aage jhuko.",
             key: "sunsal", guide: "sunsal", images: Img.sunSalutation, note: note)
    }

    // MARK: Monday — Shoulders

    static let monday = Workout(
        id: "monday", weekday: 2,
        title: "Shoulders",
        focus: "Warm-up, kandhon ka training, yoga, phir treadmill.",
        estimatedMinutes: 47,
        steps: [
            warmup("mon-warmup"),
            reps("mon-lateral", "Dumbbell lateral raises", .strength,
                 sets: 4, reps: 12, restSet: 45,
                 cue: "Haath kandhe ki height tak, control se neeche.",
                 key: "lateral", guide: "lateral", media: "Side_Lateral_Raise"),
            reps("mon-press", "Dumbbell overhead press", .strength,
                 sets: 3, reps: 10, restSet: 60,
                 cue: "Seedha upar dabao, kandhe tak neeche laao.",
                 key: "press", guide: "dbpress", media: "Standing_Dumbbell_Press"),
            reps("mon-highpull", "Kettlebell high pulls", .strength,
                 sets: 3, reps: 12, restSet: 60,
                 cue: "Chin tak kheencho, upar tez, neeche control se.",
                 key: "highpull", guide: "highpull", media: "Kettlebell_Sumo_High_Pull"),
            sun("mon-sun", rounds: 5, note: "Flow karo — saans ginne ki zaroorat nahi."),
            timed("mon-warrior1", "Warrior I", .hold,
                  seconds: 60, perSide: true, restStep: 15,
                  cue: "Pair jame hue, hips saamne ki taraf square. Ek minute har side.",
                  key: "warriors", guide: "warrior1", images: Img.warrior),
            timed("mon-warrior2", "Warrior II", .hold,
                  seconds: 60, perSide: true, restStep: 15,
                  cue: "Kandhe hips ke upar, nazar aage wale haath par. Ek minute har side.",
                  key: "warriors", guide: "warrior2", images: Img.warrior),
            timed("mon-halfmoon", "Half moon", .hold,
                  seconds: 60, perSide: true, restStep: 15,
                  cue: "Upar wala haath tan ke, seena khula. Ek minute har side.",
                  key: "halfmoon", guide: "halfmoon", images: Img.halfMoon),
            timed("mon-sideplank", "Side plank", .hold,
                  sets: 2, seconds: 40, perSide: true, restSet: 12, restStep: 20,
                  cue: "Kamar upar, core tight. Chaalis second har side.",
                  key: "sideplank", guide: "sideplank", media: "Side_Bridge"),
            treadmill("mon-cardio", "Treadmill — moderate pace", jog: true,
                      note: "Moderate pace. Phone ya YouTube pe kuch laga lo."),
        ]
    )

    // MARK: Tuesday — Core

    static let tuesday = Workout(
        id: "tuesday", weekday: 3,
        title: "Core",
        focus: "Warm-up, core ka training, flow, phir treadmill.",
        estimatedMinutes: 49,
        steps: [
            warmup("tue-warmup"),
            timed("tue-plank", "Plank holds", .hold,
                  sets: 3, seconds: 45, restSet: 20,
                  cue: "Kandhe haathon ke upar, hips level, core tight.",
                  key: "plank", guide: "plank", media: "Plank"),
            timed("tue-boat", "Boat pose", .hold,
                  sets: 3, seconds: 45, restSet: 20,
                  cue: "Seena upar, shins zameen ke parallel, thoda peeche jhuko.",
                  key: "boat", guide: "boat", images: Img.boat),
            reps("tue-mc", "Mountain climbers", .strength,
                 sets: 3, reps: 30, restSet: 30,
                 cue: "Tez par control mein. Hips level.",
                 key: "mtnclimber", guide: "mtnclimber", media: "Mountain_Climbers"),
            reps("tue-swing", "Kettlebell swings", .strength,
                 sets: 3, reps: 15, restSet: 60,
                 cue: "Hips ka dhakka, haath ka nahi.",
                 key: "swing", guide: "swing", media: "One-Arm_Kettlebell_Swings"),
            sun("tue-sun", rounds: 6),
            timed("tue-vinyasa", "Vinyasa flow", .flow,
                  seconds: 360, restStep: 20,
                  cue: "Downward dog → plank → chaturanga → upward dog. Aath baar.",
                  key: "vinyasa", guide: "vinyasa", images: Img.sunSalutation,
                  script: Script.vinyasa),
            timed("tue-childs", "Child's pose", .cooldown,
                  seconds: 120, restStep: 0,
                  cue: "Maatha zameen par, haath aage, saans peeth mein.",
                  key: "childs", guide: "childs", images: Img.childsPose,
                  script: Script.childsPose),
            treadmill("tue-cardio", "Treadmill — moderate-high run", jog: false,
                      note: "Moderate-high run. Podcast ya series laga lo."),
        ]
    )

    // MARK: Wednesday — Back

    static let wednesday = Workout(
        id: "wednesday", weekday: 4,
        title: "Back",
        focus: "Warm-up, peeth ka training, yoga, phir treadmill.",
        estimatedMinutes: 53,
        steps: [
            warmup("wed-warmup"),
            reps("wed-kb-row", "Kettlebell rows", .strength,
                 sets: 4, reps: 10, perSide: true, restSet: 60,
                 cue: "Kohni peeche, shoulder blade squeeze.",
                 key: "row", guide: "kbrow", media: "Alternating_Kettlebell_Row"),
            reps("wed-db-row", "Dumbbell rows", .strength,
                 sets: 3, reps: 12, perSide: true, restSet: 60,
                 cue: "Dumbbell pasliyon tak, neeche control se.",
                 key: "row", guide: "dbrow", media: "One-Arm_Dumbbell_Row"),
            reps("wed-highpull", "Kettlebell high pulls", .strength,
                 sets: 2, reps: 12, restSet: 60,
                 cue: "Explosive pull, chin tak.",
                 key: "highpull", guide: "highpull", media: "Kettlebell_Sumo_High_Pull"),
            sun("wed-sun", rounds: 5),
            timed("wed-warriors", "Warrior I → Warrior II flow", .flow,
                  seconds: 300, restStep: 20,
                  cue: "Poses ke beech move karo, hips ko mehsoos karo. Dono side.",
                  key: "warriors", guide: "warrior1", images: Img.warrior,
                  script: Script.warriorFlow(perSide: 150)),
            timed("wed-backbends", "Backbends (Urdhva mukha svanasana)", .hold,
                  seconds: 180, restStep: 0,
                  cue: "Seena khula, kandhe peeche, nazar thodi upar.",
                  key: "backbend", guide: "backbend", images: Img.backbend,
                  script: Script.backbends3min),
            treadmill("wed-cardio", "Treadmill — moderate pace", jog: true,
                      note: "Moderate pace. YouTube ya reels laga lo."),
        ]
    )

    // MARK: Thursday — Upper Body

    static let thursday = Workout(
        id: "thursday", weekday: 5,
        title: "Upper Body",
        focus: "Warm-up, upper body training, backbends, phir treadmill.",
        estimatedMinutes: 41,
        steps: [
            warmup("thu-warmup"),
            reps("thu-press", "Dumbbell overhead press", .strength,
                 sets: 4, reps: 10, restSet: 60,
                 cue: "Seedha upar, neeche control se.",
                 key: "press", guide: "dbpress", media: "Standing_Dumbbell_Press"),
            reps("thu-pushup", "Push-ups", .strength,
                 sets: 3, reps: 12, restSet: 45,
                 cue: "Seena zameen tak, kohni 45 degree.",
                 key: "pushup", guide: "pushup", media: "Pushups"),
            reps("thu-curl", "Dumbbell bicep curls", .strength,
                 sets: 3, reps: 15, restSet: 45,
                 cue: "Kulhon se curl, upar squeeze.",
                 key: "curl", guide: "curl", media: "Dumbbell_Bicep_Curl"),
            sun("thu-sun", rounds: 8, note: "Tez aur flowing."),
            timed("thu-backbends", "Backbends (Urdhva mukha svanasana)", .hold,
                  seconds: 240, restStep: 0,
                  cue: "Seena khula. 30 second ke teen rep.",
                  key: "backbend", guide: "backbend", images: Img.backbend,
                  script: Script.backbends4min),
            treadmill("thu-cardio", "Treadmill — moderate", jog: true,
                      note: "Moderate pace. Comedy specials, stand-up clips — inspiration mode."),
        ]
    )

    // MARK: Friday — Arms

    static let friday = Workout(
        id: "friday", weekday: 6,
        title: "Arms",
        focus: "Warm-up, arms ka training, yoga, phir easy treadmill.",
        estimatedMinutes: 54,
        steps: [
            warmup("fri-warmup"),
            reps("fri-curl", "Dumbbell bicep curls", .strength,
                 sets: 4, reps: 15, restSet: 45,
                 cue: "Slow, controlled, upar squeeze.",
                 key: "curl", guide: "curl", media: "Dumbbell_Bicep_Curl"),
            reps("fri-pushup", "Push-ups", .strength,
                 sets: 4, reps: 12, restSet: 45,
                 cue: "Poora range, seena zameen ko chhu jaye.",
                 key: "pushup", guide: "pushup", media: "Pushups"),
            reps("fri-row", "Kettlebell rows", .strength,
                 sets: 3, reps: 12, perSide: true, restSet: 60,
                 cue: "Explosive pull, control se neeche.",
                 key: "row", guide: "kbrow", media: "Alternating_Kettlebell_Row"),
            reps("fri-grip", "Hand grip strengthener", .strength,
                 sets: 3, reps: 15, perSide: true, restSet: 30,
                 cue: "Poori taakat se band karo, ek second hold, dheere chhodo.",
                 key: "grip", guide: "grip", images: Img.handGripper),
            sun("fri-sun", rounds: 6, note: "Steady pace."),
            timed("fri-warrior2", "Warrior II holds", .hold,
                  seconds: 90, perSide: true, restStep: 15,
                  cue: "Poore derh minute har side. Saans ke andar ghus jao.",
                  key: "warriors", guide: "warrior2", images: Img.warrior),
            timed("fri-camel", "Camel pose", .hold,
                  seconds: 120, restStep: 0,
                  cue: "Seena khula, kandhe peeche, halka backbend.",
                  key: "camel", guide: "camel", images: Img.camel),
            treadmill("fri-cardio", "Treadmill — easy jog/walk", jog: true,
                      note: "Easy jog ya walk. Jo dekhna ho dekho."),
        ]
    )

    // MARK: Saturday — Full Body Strength

    static let saturday = Workout(
        id: "saturday", weekday: 7,
        title: "Full Body Strength",
        focus: "Warm-up, poori body ki strength, yoga, phir treadmill.",
        estimatedMinutes: 51,
        steps: [
            warmup("sat-warmup"),
            reps("sat-press", "Kettlebell overhead press", .strength,
                 sets: 5, reps: 8, restSet: 75,
                 cue: "Max effort, control ke saath.",
                 key: "press", guide: "kbpress", media: "Two-Arm_Kettlebell_Military_Press"),
            reps("sat-swing", "Kettlebell swings", .strength,
                 sets: 4, reps: 15, restSet: 60,
                 cue: "Explosive, hips ka dhakka.",
                 key: "swing", guide: "swing", media: "One-Arm_Kettlebell_Swings"),
            reps("sat-lateral", "Dumbbell lateral raises", .strength,
                 sets: 3, reps: 15, restSet: 45,
                 cue: "Slow, squeeze. Aaj shoulder day.",
                 key: "lateral", guide: "lateral", media: "Side_Lateral_Raise",
                 note: "Shoulder day — slow aur squeeze."),
            reps("sat-tgu", "Turkish get-ups", .strength,
                 sets: 2, reps: 5, perSide: true, restSet: 90,
                 cue: "Poori body ka control. Nazar bell par.",
                 key: "tgu", guide: "tgu", media: "Kettlebell_Turkish_Get-Up_Squat_style"),
            sun("sat-sun", rounds: 5),
            timed("sat-plank", "Plank hold", .hold,
                  seconds: 60, restStep: 15,
                  cue: "Ek minute, poora tension.",
                  key: "plank", guide: "plank", media: "Plank"),
            timed("sat-boat", "Boat pose", .hold,
                  seconds: 45, restStep: 15,
                  cue: "Tight hold. Paintalis second.",
                  key: "boat", guide: "boat", images: Img.boat),
            timed("sat-warriors", "Warrior flow", .flow,
                  seconds: 180, restStep: 0,
                  cue: "Steady flow. Dono side.",
                  key: "warriors", guide: "warrior1", images: Img.warrior,
                  script: Script.warriorFlow(perSide: 90)),
            treadmill("sat-cardio", "Treadmill — high intensity / incline", jog: false,
                      note: "High intensity run ya incline walk. Series laga lo."),
        ]
    )
}
