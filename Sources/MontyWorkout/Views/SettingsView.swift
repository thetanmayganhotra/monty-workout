import SwiftUI
import AVFoundation
import AppKit

struct SettingsView: View {
    @EnvironmentObject private var history: HistoryStore
    @ObservedObject private var announcer = Announcer.shared
    @State private var confirmReset = false

    private var voices: [AVSpeechSynthesisVoice] { announcer.englishVoices() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .entrance()

                voiceCard.entrance(0.03)
                dataCard.entrance(0.06)
                aboutCard.entrance(0.09)
            }
            .padding(28)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var voiceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Voice & sound")

            Toggle("Spoken guidance", isOn: $announcer.enabled)
            Toggle("Speak coaching cues", isOn: $announcer.cues)
                .disabled(!announcer.enabled)
            Toggle("Countdown ticks", isOn: $announcer.beeps)
                .disabled(!announcer.enabled)

            Divider().overlay(Theme.surfaceHi)

            HStack {
                Text("Voice")
                    .font(.system(size: 13))
                Spacer()
                Picker("", selection: Binding(
                    get: { announcer.voiceID ?? voices.first(where: { $0.language == "en-IN" })?.identifier ?? voices.first?.identifier ?? "" },
                    set: { announcer.voiceID = $0 }
                )) {
                    ForEach(voices, id: \.identifier) { v in
                        Text("\(v.name) · \(quality(v))").tag(v.identifier)
                    }
                }
                .labelsHidden()
                .frame(width: 240)
            }

            Button {
                announcer.previewVoice()
            } label: {
                Label("Preview voice", systemImage: "speaker.wave.2.fill")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.accent)

            Text("Awaaz: free neural Hindi voice (Madhur workout ke liye, Swara meditation ke liye) — pehle se record ki hui, offline chalti hai. Upar wali system voice sirf tab bajti hai jab kisi line ka recording nahi hota. Currently: \(announcer.currentVoiceLabel).")
                .font(.system(size: 11))
                .foregroundStyle(Theme.faint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card(20)
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Data")
            Text("History is stored locally as history.json.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)

            HStack(spacing: 10) {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([history.storageDirectory])
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.accent)

                Button(role: .destructive) {
                    confirmReset = true
                } label: {
                    Label("Reset history", systemImage: "trash")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.miss)
            }
        }
        .card(20)
        .confirmationDialog("Delete all workout history?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { history.resetAll() }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "About")
            Text("Monty Workout — a minimal companion for the 6-day kettlebell + yoga routine. Exercise imagery from the public-domain free-exercise-db project.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card(20)
    }

    private func quality(_ v: AVSpeechSynthesisVoice) -> String {
        switch v.quality {
        case .premium: "Premium"
        case .enhanced: "Enhanced"
        default: "Default"
        }
    }
}
