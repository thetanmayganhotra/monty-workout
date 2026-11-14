import SwiftUI
import AppKit

/// Loads follow-along frames from either a free-exercise-db id (two position
/// photos) or explicit image URLs (Wikimedia Commons yoga illustrations —
/// one `.gif` animates, one still gets a slow zoom, two stills cross-fade).
@MainActor
final class FrameLoader: ObservableObject {
    @Published var frames: [NSImage] = []
    @Published var animatedGIF: NSImage?
    @Published var didFail = false

    private var token: String?
    private static let exdb = "https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises"

    func load(mediaID: String?, imageURLs: [String]?) {
        let key = (imageURLs?.joined(separator: "|")) ?? mediaID ?? ""
        guard token != key else { return }
        token = key
        frames = []
        animatedGIF = nil
        didFail = false

        if let urls = imageURLs, !urls.isEmpty {
            loadURLs(urls, key: key)
        } else if let mediaID {
            let urls = (0...1).map { "\(Self.exdb)/\(pathEncode("\(mediaID)/\($0).jpg"))" }
            loadURLs(urls, key: key)
        }
    }

    private func loadURLs(_ urls: [String], key: String) {
        Task { [urls, key] in
            if let first = urls.first, first.lowercased().hasSuffix(".gif") {
                if let img = await Self.fetch(first) {
                    guard token == key else { return }
                    animatedGIF = img
                } else { didFail = true }
                return
            }
            var collected: [NSImage] = []
            for u in urls.prefix(2) {
                if let img = await Self.fetch(u) { collected.append(img) }
            }
            guard token == key else { return }
            if collected.isEmpty { didFail = true } else { frames = collected }
        }
    }

    private func pathEncode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? s
    }

    private static func fetch(_ urlString: String) async -> NSImage? {
        guard let url = URL(string: urlString) else { return nil }
        var req = URLRequest(url: url)
        req.setValue("MontyWorkout/1.0 (personal fitness app)", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let image = NSImage(data: data) else { return nil }
            return image
        } catch {
            return nil
        }
    }
}

/// Wraps NSImageView so an animated GIF actually plays.
private struct AnimatedImage: NSViewRepresentable {
    let image: NSImage
    func makeNSView(context: Context) -> NSImageView {
        let v = NSImageView()
        v.imageScaling = .scaleProportionallyUpOrDown
        v.animates = true
        v.image = image
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        v.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return v
    }
    func updateNSView(_ v: NSImageView, context: Context) {
        v.image = image
        v.animates = true
    }
}

struct GifView: View {
    let mediaID: String?
    let kind: StepKind
    var title: String = ""
    var imageURLs: [String]? = nil
    var symbolOverride: String? = nil
    var height: CGFloat = 300

    @StateObject private var loader = FrameLoader()
    @State private var frame = 0
    @State private var pulse = false
    @State private var zoom = false

    private let cycle = Timer.publish(every: 1.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Theme.surfaceHi, lineWidth: 1)
                )

            if let gif = loader.animatedGIF {
                AnimatedImage(image: gif)
                    .padding(14)
            } else if loader.frames.count >= 2 {
                ForEach(Array(loader.frames.enumerated()), id: \.offset) { idx, image in
                    Image(nsImage: image)
                        .resizable().interpolation(.high).scaledToFit().padding(18)
                        .opacity(idx == frame % loader.frames.count ? 1 : 0)
                }
                .animation(.easeInOut(duration: 0.55), value: frame)
            } else if let still = loader.frames.first {
                Image(nsImage: still)
                    .resizable().interpolation(.high).scaledToFit().padding(18)
                    .scaleEffect(zoom ? 1.05 : 0.98)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: zoom)
                    .onAppear { zoom = true }
            } else if loader.didFail || (mediaID == nil && imageURLs == nil) {
                placeholder
            } else {
                ProgressView().controlSize(.small).tint(Theme.dim)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onAppear { loader.load(mediaID: mediaID, imageURLs: imageURLs); pulse = true }
        .onChange(of: mediaID) { _, _ in reload() }
        .onChange(of: imageURLs ?? []) { _, _ in reload() }
        .onReceive(cycle) { _ in
            if loader.frames.count > 1 { frame += 1 }
        }
    }

    private func reload() {
        frame = 0
        loader.load(mediaID: mediaID, imageURLs: imageURLs)
    }

    private var placeholder: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 128, height: 128)
                    .scaleEffect(pulse ? 1.08 : 0.92)
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: pulse)
                Image(systemName: symbolOverride ?? symbol)
                    .font(.system(size: 52, weight: .thin))
                    .foregroundStyle(Theme.accent)
            }
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Text("follow the spoken cue")
                .font(.system(size: 11))
                .foregroundStyle(Theme.faint)
        }
    }

    private var symbol: String {
        switch kind {
        case .warmup:   return "figure.cooldown"
        case .strength: return "figure.strengthtraining.traditional"
        case .hold:     return "figure.core.training"
        case .flow:     return "figure.yoga"
        case .cardio:   return "figure.run"
        case .cooldown: return "figure.mind.and.body"
        }
    }
}
