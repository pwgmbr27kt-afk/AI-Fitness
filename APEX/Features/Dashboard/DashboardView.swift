import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query(sort: \APEXTask.date, order: .reverse) private var allTasks: [APEXTask]
    @Query(sort: \DayNutrition.date, order: .reverse) private var nutritionDays: [DayNutrition]
    @Query(sort: \BodyEntry.date, order: .reverse) private var bodyEntries: [BodyEntry]
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt == nil }) private var pendingWorkouts: [WorkoutSession]
    @Query(sort: \Reminder.scheduledTime) private var reminders: [Reminder]

    private var profile: UserProfile? { profiles.first }

    private var todaysTasks: [APEXTask] {
        allTasks.filter { $0.date.isToday }
    }

    private var completedTasks: [APEXTask] {
        todaysTasks.filter(\.isCompleted)
    }

    private var taskProgress: Double {
        guard !todaysTasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(todaysTasks.count)
    }

    private var todayNutrition: DayNutrition? {
        nutritionDays.first { $0.date.isToday }
    }

    private var nextReminder: Reminder? {
        reminders.filter(\.isActive).first
    }

    private var last7WeightEntries: [BodyEntry] {
        Array(bodyEntries.prefix(7).reversed())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        // Greeting
                        greetingHeader
                            .apexPadding()

                        // Progress rings row
                        ringsRow
                            .apexPadding()

                        // Today's tasks preview
                        tasksSummaryCard
                            .apexPadding()

                        // Weight mini chart
                        if last7WeightEntries.count >= 2 {
                            weightTrendCard
                                .apexPadding()
                        }

                        // Next reminder
                        if let reminder = nextReminder {
                            nextReminderCard(reminder: reminder)
                                .apexPadding()
                        }

                        // Stats row
                        statsRow
                            .apexPadding()
                    }
                    .padding(.top, Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.apexTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Greeting
    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.apexCallout)
                    .foregroundStyle(.apexTextSecondary)
                Text(profile?.name ?? "Athlete")
                    .font(.apexLargeTitle)
                    .foregroundStyle(.apexTextPrimary)
            }
            Spacer()
            Text(Date().formatted(.dateTime.day().month(.wide)))
                .font(.apexCallout)
                .foregroundStyle(.apexTextSecondary)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Guten Morgen,"
        case 12..<17: return "Guten Mittag,"
        case 17..<22: return "Guten Abend,"
        default:      return "Gute Nacht,"
        }
    }

    // MARK: - Rings
    private var ringsRow: some View {
        GlassCard {
            HStack(spacing: Spacing.lg) {
                // Task progress
                VStack(spacing: 4) {
                    RingProgressView(
                        progress: taskProgress,
                        size: 72,
                        color: .apexCyan,
                        showPercent: true
                    )
                    Text("Aufgaben")
                        .font(.apexCaption)
                        .foregroundStyle(.apexTextSecondary)
                }

                // Calories
                VStack(spacing: 4) {
                    RingProgressView(
                        progress: todayNutrition?.calorieProgress ?? 0,
                        size: 72,
                        color: .apexOrange,
                        label: todayNutrition.map { "\($0.totalCalories)" } ?? "0",
                        sublabel: "kcal"
                    )
                    Text("Kalorien")
                        .font(.apexCaption)
                        .foregroundStyle(.apexTextSecondary)
                }

                // Protein
                VStack(spacing: 4) {
                    RingProgressView(
                        progress: todayNutrition?.proteinProgress ?? 0,
                        size: 72,
                        color: .apexPurple,
                        label: todayNutrition.map { "\(Int($0.totalProtein))g" } ?? "0g",
                        sublabel: "Protein"
                    )
                    Text("Protein")
                        .font(.apexCaption)
                        .foregroundStyle(.apexTextSecondary)
                }

                // Water
                VStack(spacing: 4) {
                    let waterGoal = Double(profile?.waterGoalMl ?? AppConfiguration.defaultWaterGoalMl)
                    let waterMl = Double(todayNutrition?.waterMl ?? 0)
                    RingProgressView(
                        progress: waterGoal > 0 ? waterMl / waterGoal : 0,
                        size: 72,
                        color: .apexBlue,
                        label: todayNutrition.map { "\($0.waterMl / 1000)L" } ?? "0L",
                        sublabel: "Wasser"
                    )
                    Text("Wasser")
                        .font(.apexCaption)
                        .foregroundStyle(.apexTextSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Tasks Summary
    private var tasksSummaryCard: some View {
        VStack(spacing: Spacing.sm) {
            SectionHeader(title: "Heute", actionLabel: "Alle") {}

            if todaysTasks.isEmpty {
                GlassCard {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.apexCyan)
                        Text("Keine Aufgaben heute")
                            .font(.apexBody)
                            .foregroundStyle(.apexTextSecondary)
                        Spacer()
                    }
                }
            } else {
                GlassCard(padding: Spacing.sm) {
                    VStack(spacing: 0) {
                        ForEach(todaysTasks.prefix(4)) { task in
                            TaskRow(task: task)
                                .padding(.horizontal, Spacing.sm)
                            if task.id != todaysTasks.prefix(4).last?.id {
                                Divider().background(.white.opacity(0.06))
                                    .padding(.leading, 56)
                            }
                        }
                        if todaysTasks.count > 4 {
                            Text("+ \(todaysTasks.count - 4) weitere")
                                .font(.apexCaption)
                                .foregroundStyle(.apexTextTertiary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, Spacing.sm)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Weight Trend
    private var weightTrendCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Gewichtsverlauf", actionLabel: "Details") {}

                Chart(last7WeightEntries) { entry in
                    LineMark(
                        x: .value("Datum", entry.date),
                        y: .value("Gewicht", entry.weightKg)
                    )
                    .foregroundStyle(Color.apexCyan)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Datum", entry.date),
                        y: .value("Gewicht", entry.weightKg)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [.apexCyan.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom)
                    )
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 80)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .trailing) { val in
                        AxisValueLabel {
                            if let d = val.as(Double.self) {
                                Text("\(Int(d))")
                                    .font(.apexCaption)
                                    .foregroundStyle(.apexTextTertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Next Reminder
    private func nextReminderCard(_ reminder: Reminder) -> some View {
        GlassCard {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.apexCyan.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: reminder.category.icon)
                        .foregroundStyle(.apexCyan)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Nächste Erinnerung")
                        .font(.apexCaption)
                        .foregroundStyle(.apexTextTertiary)
                    Text(reminder.title)
                        .font(.apexBody)
                        .foregroundStyle(.apexTextPrimary)
                }

                Spacer()

                Text(reminder.scheduledTime.timeFormatted)
                    .font(.apexCallout)
                    .foregroundStyle(.apexCyan)
            }
        }
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: Spacing.md) {
            StatCard(
                icon: "dumbbell.fill",
                value: "\(completedWorkoutsThisWeek)",
                label: "Workouts diese Woche",
                accentColor: .apexCyan
            )
            StatCard(
                icon: "scalemass.fill",
                value: bodyEntries.first.map { String(format: "%.1f kg", $0.weightKg) } ?? "–",
                label: "Aktuelles Gewicht",
                accentColor: .apexBlue
            )
        }
    }

    private var completedWorkoutsThisWeek: Int {
        let weekStart = Calendar.current.startOfWeek(for: Date())
        return 0 // Will be populated from WorkoutSession data
    }
}
