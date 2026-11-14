import SwiftUI

struct RootView: View {
    @EnvironmentObject private var history: HistoryStore
    @StateObject private var session = WorkoutSession()
    @State private var tab: Tab = .today
    @Namespace private var pill

    enum Tab: String, CaseIterable, Identifiable {
        case today = "Today", history = "History", schedule = "Schedule", settings = "Settings"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .today: "flame"
            case .history: "calendar"
            case .schedule: "list.bullet.rectangle"
            case .settings: "slider.horizontal.3"
            }
        }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            HStack(spacing: 0) {
                sidebar
                Rectangle().fill(Theme.surfaceHi).frame(width: 1).ignoresSafeArea()
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if session.isRunning {
                SessionView()
                    .environmentObject(session)
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    .zIndex(10)
            }
        }
        .environmentObject(session)
        .environmentObject(Announcer.shared)
        .preferredColorScheme(.dark)
        .foregroundStyle(Theme.text)
        .tint(Theme.accent)
        .animation(Theme.springSmooth, value: session.isRunning)
    }

    @ViewBuilder private var content: some View {
        Group {
            switch tab {
            case .today:    TodayView()
            case .history:  HistoryView()
            case .schedule: ScheduleView()
            case .settings: SettingsView()
            }
        }
        .id(tab)
        .transition(.opacity.combined(with: .scale(scale: 0.985)))
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 9) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.accentGradient)
                        .frame(width: 26, height: 26)
                        .shadow(color: Theme.accent.opacity(0.5), radius: 7, y: 3)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("Monty")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 12)
            .padding(.top, 18)
            .padding(.bottom, 22)

            ForEach(Tab.allCases) { item in
                SidebarRow(item: item, selected: tab == item, pill: pill) {
                    withAnimation(Theme.springSnappy) { tab = item }
                }
            }

            Spacer()

            let streak = history.currentStreak()
            if streak > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Theme.accentGradient)
                        .symbolEffect(.pulse, options: .repeating.speed(0.5))
                    Text("\(streak) day streak")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.dim)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .frame(width: 190)
        .background(Theme.bg)
        .animation(Theme.springSmooth, value: streakVisible)
    }

    private var streakVisible: Bool { history.currentStreak() > 0 }
}

private struct SidebarRow: View {
    let item: RootView.Tab
    let selected: Bool
    let pill: Namespace.ID
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .frame(width: 18)
                    .symbolVariant(selected ? .fill : .none)
                Text(item.rawValue)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                ZStack {
                    if selected {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Theme.surfaceHi)
                            .matchedGeometryEffect(id: "pill", in: pill)
                    } else if hovering {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Theme.surfaceHi.opacity(0.5))
                    }
                }
            )
            .foregroundStyle(selected ? Theme.text : Theme.dim)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(Theme.springSnappy, value: hovering)
    }
}
