import Foundation

/// One thing the app says out loud. `calm` picks the softer, slower delivery
/// used for breathing and meditation.
struct Utterance: Hashable {
    let text: String
    let calm: Bool
}

/// Every spoken phrase is built here so the app and the voice-pack generator
/// (Voice/tools) always agree on the exact strings.
enum Phrases {
    static let genericSubtitles: Set<String> = ["Hold", "Work", "Guided", "Steady"]

    static let switchSides = "Side badlo."
    static let nextPrefix  = "Agla:"
    static let tenSeconds  = "Das second."
    static let timeUp      = "Ho gaya."
    static let preview     = "Chalo shuru karte hain. Set do, aath reps. Kandhe dheele, seedha upar dabao."

    // MARK: Effort intro pieces

    static func name(_ e: EffortSpec) -> Utterance { Utterance(text: e.title, calm: e.isGuided) }

    /// "Set 2 of 4" → "Set 2, 4 mein se."   ·   "Left side" → "Baayein side."
    static func setLine(_ e: EffortSpec) -> Utterance? {
        let sub = e.subtitle
        guard !genericSubtitles.contains(sub) else { return nil }

        func side(_ s: String) -> String {
            s.replacingOccurrences(of: "Left side", with: "baayein side")
             .replacingOccurrences(of: "Right side", with: "daayein side")
        }

        var text: String
        if sub.hasPrefix("Set "), sub.contains(" of ") {
            // "Set 2 of 4"
            let parts = sub.dropFirst(4).components(separatedBy: " of ")
            text = "Set \(parts[0]), \(parts.count > 1 ? parts[1] : "") mein se."
        } else if sub.contains(" · ") {
            // "Set 1 · Left side"
            let parts = sub.components(separatedBy: " · ")
            text = "\(parts[0]), \(side(parts[1]))."
        } else {
            let t = side(sub)
            text = t.prefix(1).uppercased() + t.dropFirst() + "."
        }
        return Utterance(text: text, calm: e.isGuided)
    }

    static func target(_ e: EffortSpec) -> Utterance? {
        if let r = e.reps {
            let noun = e.repNoun
            let text: String
            if noun.contains("/ leg") {
                text = "\(r) reps har leg."
            } else if e.perSide {
                text = "Har side \(r) \(noun)."
            } else {
                text = "\(r) \(noun)."
            }
            return Utterance(text: text, calm: e.isGuided)
        }
        if let s = e.seconds {
            return Utterance(text: spokenDuration(s) + (e.perSide ? " har side." : "."), calm: e.isGuided)
        }
        return nil
    }

    static func duration(_ seconds: Int) -> Utterance {
        Utterance(text: spokenDuration(seconds) + ".", calm: false)
    }

    // MARK: Guide

    static func guideStep(_ g: Guide, _ i: Int) -> String {
        let lead = ["Pehle", "Phir", "Uske baad", "Aakhir mein", "Phir", "Aur ab"][min(i, 5)]
        return "\(lead), \(g.steps[i].text)"
    }

    /// All the steps of a guide, in order.
    static func guideSteps(_ g: Guide, calm: Bool) -> [Utterance] {
        g.steps.indices.map { Utterance(text: guideStep(g, $0), calm: calm) }
    }

    // MARK: Whole-app catalogue (used by the voice-pack generator)

    @MainActor
    static func catalogue(workouts: [Workout]) -> [Utterance] {
        var out = Set<Utterance>()
        func add(_ t: String, calm: Bool = false) { if !t.isEmpty { out.insert(Utterance(text: t, calm: calm)) } }

        for w in workouts {
            for seg in WorkoutSession.buildPlan(w) {
                switch seg {
                case .effort(let e):
                    out.insert(name(e))
                    if let s = setLine(e) { out.insert(s) }
                    if let t = target(e) { out.insert(t) }
                    if let s = e.seconds { out.insert(duration(s)) }
                    if let g = GuideBank.guide(e.guideKey ?? e.cueKey) {
                        if e.isGuided {
                            out.insert(Utterance(text: guideStep(g, 0), calm: true))
                        } else {
                            for u in guideSteps(g, calm: false) { out.insert(u) }
                        }
                    }
                    if let note = e.note { add(note, calm: e.isGuided) }
                    if let mid = e.midCue, !e.isGuided { add(mid) }
                    if let lines = e.script { for l in lines { add(l.text, calm: true) } }
                    if let b = e.breath {
                        for p in b.phases { add(p.say, calm: true); if let f = p.firstSay { add(f, calm: true) } }
                    }
                    // "Agla: <title>" while resting
                    out.insert(Utterance(text: e.title, calm: false))
                case .rest:
                    break
                }
            }
        }

        // Rotating lines
        for pool in CueBank.pools.values { for l in pool { add(l) } }
        for pool in CueBank.byKind.values { for l in pool { add(l) } }
        for l in CueBank.starts + CueBank.restFlavour + CueBank.setDone + CueBank.finishes { add(l) }

        // Fixed phrases
        for l in [switchSides, nextPrefix, tenSeconds, timeUp, preview] { add(l) }

        return out.sorted { ($0.calm ? 1 : 0, $0.text) < ($1.calm ? 1 : 0, $1.text) }
    }
}
