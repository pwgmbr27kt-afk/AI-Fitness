import SwiftUI
import SwiftData

struct TrainingRootView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                TabView {
                    WorkoutPlanView()
                        .tabItem { Label("Plan", systemImage: "calendar.badge.checkmark") }
                    WorkoutHistoryView()
                        .tabItem { Label("Verlauf", systemImage: "clock.arrow.circlepath") }
                    ProgressRootView()
                        .tabItem { Label("Fortschritt", systemImage: "chart.line.uptrend.xyaxis") }
                }
                .tint(.apexCyan)
            }
            .navigationTitle("Training")
        }
    }
}

// MARK: - Workout Plan View
struct WorkoutPlanView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var showAddSession = false

    private var weekSessions: [Weekday: WorkoutSession?] {
        var dict: [Weekday: WorkoutSession?] = [:]
        for day in Weekday.allCases {
            dict[day] = sessions.first { s in
                guard let weekday = s.date.weekday else { return false }
                return weekday == day && Calendar.current.isDate(s.date, equalTo: Date(), toGranularity: .weekOfYear)
            }
        }
        return dict
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(Weekday.allCases) { day in
                    WeekDayCard(day: day, session: weekSessions[day] ?? nil)
                        .apexPadding()
                }

                APEXButton(title: "Session hinzufügen", icon: "plus") { showAddSession = true }
                    .padding(.horizontal, Spacing.md)
            }
            .padding(.vertical, Spacing.md)
        }
        .sheet(isPresented: $showAddSession) {
            WorkoutSessionEditorView()
        }
    }
}

struct WeekDayCard: View {
    var day: Weekday
    var session: WorkoutSession?
    @State private var showSession = false

    var body: some View {
        Button { if session != nil { showSession = true } } label: {
            GlassCard {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(day.fullName)
                            .font(.apexHeadline)
                            .foregroundStyle(isToday ? .apexCyan : .apexTextPrimary)
                        if let session {
                            Text(session.name)
                                .font(.apexCallout)
                                .foregroundStyle(.apexTextSecondary)
                        } else {
                            Text("Ruhetag")
                                .font(.apexCallout)
                                .foregroundStyle(.apexTextTertiary)
                        }
                    }
                    Spacer()
                    if session?.isCompleted == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.apexGreen)
                    } else if session != nil {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.apexTextTertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSession) {
            if let s = session {
                ActiveWorkoutView(session: s)
            }
        }
    }

    private var isToday: Bool {
        Weekday.today == day
    }
}

// MARK: - Workout History
struct WorkoutHistoryView: View {
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.date,
        order: .reverse
    ) private var completedSessions: [WorkoutSession]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(completedSessions) { session in
                    NavigationLink(destination: WorkoutSummaryView(session: session)) {
                        GlassCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.name)
                                        .font(.apexHeadline)
                                        .foregroundStyle(.apexTextPrimary)
                                    Text(session.date.relativeFormatted)
                                        .font(.apexCallout)
                                        .foregroundStyle(.apexTextSecondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(String(format: "%.0f kg", session.totalVolume))
                                        .font(.apexHeadline)
                                        .foregroundStyle(.apexCyan)
                                    Text("Volumen")
                                        .font(.apexCaption)
                                        .foregroundStyle(.apexTextTertiary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .apexPadding()
                }
            }
            .padding(.vertical, Spacing.md)
        }
    }
}
