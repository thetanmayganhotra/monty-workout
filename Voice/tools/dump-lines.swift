import Foundation

// Prints every phrase the app can speak as JSON: [{"text": "...", "calm": false}, ...]
@main struct Dump {
    @MainActor static func main() {
        let all = Phrases.catalogue(workouts: Schedule.all)
        let arr = all.map { ["text": $0.text, "calm": $0.calm] as [String: Any] }
        let data = try! JSONSerialization.data(withJSONObject: arr, options: [.prettyPrinted, .sortedKeys])
        FileHandle.standardOutput.write(data)
    }
}
