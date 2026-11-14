import AVFoundation
import AppKit
import CryptoKit

/// Finds pre-recorded neural-voice clips for the app's phrases.
///
/// Every phrase the app speaks is rendered ahead of time (see Voice/) with a
/// proper Hindi neural voice from Devanagari text — Roman-script Hinglish read
/// by an English voice is gibberish. Clips are looked up by a hash of the exact
/// phrase; anything without a clip falls back to the system voice.
enum VoicePack {
    static func key(_ u: Utterance) -> String {
        let digest = Insecure.SHA1.hash(data: Data("\(u.calm ? "c" : "n")|\(u.text)".utf8))
        return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    private static let directory: URL? = {
        let fm = FileManager.default
        if let r = Bundle.main.resourceURL?.appendingPathComponent("Voice", isDirectory: true),
           fm.fileExists(atPath: r.path) { return r }
        // `swift run` during development: walk up from the binary looking for Voice/clips.
        var dir = Bundle.main.executableURL?.deletingLastPathComponent()
        for _ in 0..<7 {
            if let d = dir?.appendingPathComponent("Voice/clips", isDirectory: true),
               fm.fileExists(atPath: d.path) { return d }
            dir = dir?.deletingLastPathComponent()
        }
        return nil
    }()

    private static var reported = Set<String>()

    static var isAvailable: Bool { directory != nil }

    static func url(for u: Utterance) -> URL? {
        guard let dir = directory else { return nil }
        let f = dir.appendingPathComponent("\(key(u)).mp3")
        return FileManager.default.fileExists(atPath: f.path) ? f : nil
    }

    static func reportMiss(_ u: Utterance) {
        guard reported.insert(u.text).inserted else { return }
        FileHandle.standardError.write(Data("[voice] no clip for: \(u.text)\n".utf8))
    }
}

/// Spoken coaching + countdown cues. Plays the pre-recorded neural clips, in order,
/// and falls back to the system voice for anything that has no clip.
@MainActor
final class Announcer: NSObject, ObservableObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    static let shared = Announcer()

    private let synth = AVSpeechSynthesizer()

    private enum Key {
        static let enabled = "announcer.enabled"
        static let cues = "announcer.cues"
        static let beeps = "announcer.beeps"
        static let voice = "announcer.voiceID"
    }

    @Published var enabled: Bool { didSet { UserDefaults.standard.set(enabled, forKey: Key.enabled) } }
    /// Speak the coaching cue lines (as opposed to just names + countdowns).
    @Published var cues: Bool { didSet { UserDefaults.standard.set(cues, forKey: Key.cues) } }
    /// Play a short tick on the final 3 seconds and a tone when rest ends.
    @Published var beeps: Bool { didSet { UserDefaults.standard.set(beeps, forKey: Key.beeps) } }
    /// Only used for the system-voice fallback.
    @Published var voiceID: String? {
        didSet { UserDefaults.standard.set(voiceID, forKey: Key.voice) }
    }

    private enum Item { case clip(URL), tts(String, Bool) }
    private var queue: [Item] = []
    private var busy = false
    private var player: AVAudioPlayer?
    private var currentUtterance: AVSpeechUtterance?

    private override init() {
        let d = UserDefaults.standard
        enabled = d.object(forKey: Key.enabled) as? Bool ?? true
        cues    = d.object(forKey: Key.cues) as? Bool ?? true
        beeps   = d.object(forKey: Key.beeps) as? Bool ?? true
        voiceID = d.string(forKey: Key.voice)
        super.init()
        synth.delegate = self
    }

    // MARK: Fallback voice selection

    private static let noveltyVoices: Set<String> = [
        "Albert", "Bad News", "Bahh", "Bells", "Boing", "Bubbles", "Cellos", "Deranged",
        "Eddy", "Flo", "Fred", "Good News", "Grandma", "Grandpa", "Jester", "Junior",
        "Kathy", "Organ", "Princess", "Ralph", "Reed", "Rocko", "Sandy", "Shelley",
        "Superstar", "Trinoids", "Whisper", "Wobble", "Zarvox", "Hysterical",
    ]

    /// English voices, most natural first, novelty voices removed.
    func englishVoices() -> [AVSpeechSynthesisVoice] {
        let english = AVSpeechSynthesisVoice.speechVoices().filter { (v: AVSpeechSynthesisVoice) in
            guard v.language.hasPrefix("en") else { return false }
            return !Self.noveltyVoices.contains(where: { v.name.hasPrefix($0) })
        }
        return english.sorted { (lhs: AVSpeechSynthesisVoice, rhs: AVSpeechSynthesisVoice) in
            if lhs.quality.rank != rhs.quality.rank { return lhs.quality.rank > rhs.quality.rank }
            return lhs.name < rhs.name
        }
    }

    private func resolvedVoice() -> AVSpeechSynthesisVoice? {
        if let id = voiceID, let v = AVSpeechSynthesisVoice(identifier: id) { return v }
        let all = englishVoices()
        return all.first(where: { $0.language == "en-IN" }) ?? all.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    var currentVoiceLabel: String {
        VoicePack.isAvailable ? "Neural Hindi voice pack" : {
            guard let v = resolvedVoice() else { return "System default" }
            return "\(v.name) · \(v.quality.label)"
        }()
    }

    // MARK: Speaking

    /// Test hook: sees every phrase requested, even when speech is disabled.
    var tap: ((Utterance) -> Void)?

    /// Queue a phrase. `interrupt` cuts whatever is playing first; `calm` selects the
    /// slower, softer recording used for breathing and meditation.
    func say(_ text: String, interrupt: Bool = false, calm: Bool = false) {
        if !text.isEmpty { tap?(Utterance(text: text, calm: calm)) }
        guard enabled, !text.isEmpty else { return }
        if interrupt { stop() }
        let u = Utterance(text: text, calm: calm)
        if let url = VoicePack.url(for: u) {
            queue.append(.clip(url))
        } else {
            VoicePack.reportMiss(u)
            queue.append(.tts(text, calm))
        }
        pump()
    }

    func stop() {
        queue.removeAll()
        let p = player, cur = currentUtterance
        player = nil
        currentUtterance = nil
        busy = false
        p?.stop()
        if cur != nil { synth.stopSpeaking(at: .immediate) }
    }

    func previewVoice() { say(Phrases.preview, interrupt: true) }

    private func pump() {
        guard !busy, !queue.isEmpty else { return }
        busy = true
        switch queue.removeFirst() {
        case .clip(let url):
            do {
                let p = try AVAudioPlayer(contentsOf: url)
                p.delegate = self
                player = p
                if !p.play() { finishItem() }
            } catch {
                finishItem()
            }
        case .tts(let text, let calm):
            let u = AVSpeechUtterance(string: text)
            u.voice = resolvedVoice()
            u.rate = AVSpeechUtteranceDefaultSpeechRate * (calm ? 0.80 : 0.94)
            u.pitchMultiplier = calm ? 0.95 : 1.0
            currentUtterance = u
            synth.speak(u)
        }
    }

    private func finishItem() {
        player = nil
        currentUtterance = nil
        busy = false
        pump()
    }

    // MARK: Delegates

    nonisolated func audioPlayerDidFinishPlaying(_ p: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in if self.player === p { self.finishItem() } }
    }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        Task { @MainActor in if self.currentUtterance === u { self.finishItem() } }
    }

    // MARK: Sound cues

    func tick() {
        guard enabled, beeps else { return }
        NSSound(named: NSSound.Name("Tink"))?.play()
    }

    func chime() {
        guard enabled, beeps else { return }
        NSSound(named: NSSound.Name("Glass"))?.play()
    }
}

private extension AVSpeechSynthesisVoiceQuality {
    var rank: Int {
        switch self {
        case .premium:  return 3
        case .enhanced: return 2
        case .default:  return 1
        @unknown default: return 0
        }
    }
    var label: String {
        switch self {
        case .premium:  return "Premium"
        case .enhanced: return "Enhanced"
        case .default:  return "Default"
        @unknown default: return "Voice"
        }
    }
}
