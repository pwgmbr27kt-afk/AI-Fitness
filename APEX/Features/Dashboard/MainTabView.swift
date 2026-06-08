import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
                .tag(0)

            DayPlannerView()
                .tabItem { Label("Tagesplan", systemImage: "calendar.day.timeline.left") }
                .tag(1)

            TrainingRootView()
                .tabItem { Label("Training", systemImage: "dumbbell.fill") }
                .tag(2)

            NutritionRootView()
                .tabItem { Label("Ernährung", systemImage: "fork.knife") }
                .tag(3)

            MehrView()
                .tabItem { Label("Mehr", systemImage: "ellipsis.circle.fill") }
                .tag(4)
        }
        .tint(.apexCyan)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

// MARK: - Mehr (More) Hub
struct MehrView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        mehreRow(icon: "brain.head.profile", title: "KI-Coach", subtitle: "Persönlicher Assistent", color: .apexCyan) {
                            AICoachView()
                        }
                        mehreRow(icon: "chart.line.uptrend.xyaxis", title: "Fortschritt", subtitle: "Gewicht & Körper", color: .apexBlue) {
                            ProgressRootView()
                        }
                        mehreRow(icon: "figure.flexibility", title: "Mobility & Dehnung", subtitle: "Routinen & Timer", color: .apexGreen) {
                            MobilityView()
                        }
                        mehreRow(icon: "person.crop.rectangle.stack.fill", title: "Körperanalyse", subtitle: "Fotos & KI-Auswertung", color: .apexPurple) {
                            BodyAnalysisView()
                        }
                        mehreRow(icon: "calendar", title: "Kalender", subtitle: "Monatsübersicht", color: .apexOrange) {
                            KalenderView()
                        }
                        mehreRow(icon: "chart.bar.fill", title: "Statistiken", subtitle: "Auswertungen & Trends", color: .apexYellow) {
                            StatisticsView()
                        }
                        mehreRow(icon: "bell.fill", title: "Erinnerungen", subtitle: "Benachrichtigungen", color: .apexRed) {
                            RemindersView()
                        }
                        mehreRow(icon: "gearshape.fill", title: "Einstellungen", subtitle: "Profil & Konfiguration", color: .apexTextSecondary) {
                            SettingsView()
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Mehr")
        }
    }

    @ViewBuilder
    private func mehreRow<D: View>(icon: String, title: String, subtitle: String, color: Color, @ViewBuilder destination: () -> D) -> some View {
        NavigationLink(destination: destination()) {
            GlassCard {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(color.opacity(0.18))
                            .frame(width: 48, height: 48)
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(color)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.apexHeadline)
                            .foregroundStyle(.apexTextPrimary)
                        Text(subtitle)
                            .font(.apexCallout)
                            .foregroundStyle(.apexTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.apexTextTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
