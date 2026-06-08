import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)

            DayPlannerView()
                .tabItem {
                    Label("Planer", systemImage: "calendar")
                }
                .tag(1)

            TrainingRootView()
                .tabItem {
                    Label("Training", systemImage: "dumbbell.fill")
                }
                .tag(2)

            NutritionRootView()
                .tabItem {
                    Label("Ernährung", systemImage: "fork.knife")
                }
                .tag(3)

            AICoachView()
                .tabItem {
                    Label("Coach", systemImage: "brain.head.profile")
                }
                .tag(4)
        }
        .tint(.apexCyan)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
