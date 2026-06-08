import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query(sort: \APEXTask.createdAt) private var allTasks: [APEXTask]
    @Query(sort: \DayNutrition.date, order: .reverse) private var nutritionDays: [DayNutrition]
    @Query(sort: \BodyEntry.date, order: .reverse) private var bodyEntries: [BodyEntry]
    @Query(sort: \Reminder.scheduledTime) private var reminders: [Reminder]
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.date, order: .reverse
    ) private var completedSessions: [WorkoutSession]

    @State private var showQuickAdd = false

    private var profile: UserProfile? { profiles.first }

    private var todaysTasks: [APEXTask] {
        let today = Calendar.current.startOfDay(for: Date())
        return allTasks.filter {
            Calendar.current.startOfDay(for: $0.date) == today ||
            ($0.isRepeating && $0.repeatDays.contains(Date().weekday ?? .monday))
        }
    }
    private var completedToday: Int { todaysTasks.filter(\.isCompleted).count }
    private var taskProgress: Double {
        guard !todaysTasks.isEmpty else { return 0 }
        return Double(completedToday) / Double(todaysTasks.count)
    }
    private var todayNutrition: DayNutrition? {
        nutritionDays.first { Calendar.current.isDateInToday($0.date) }
    }
    private var nextReminder: Reminder? {
        reminders.first(where: { $0.isActive })
    }
    private var last7Weights: [BodyEntry] {
        Array(bodyEntries.prefix(7).reversed())
    }
    private var sessionsThisWeek: Int {
        let weekStart = Calendar.current.startOfWeek(for: Date())
        return completedSessions.filter { $0.date >= weekStart }.count
    }
    private var habitScoreThisWeek: Double {
        let weekTasks = allTasks.filter { t in
            guard let weekday = t.date.weekday else { return false }
            let weekStart = Calendar.current.startOfWeek(for: Date())
            return t.date >= weekStart && t.isRepeating
        }
        guard !weekTasks.isEmpty else { return 0 }
        return Double(weekTasks.filter(\.isCompleted).count) / Double(weekTasks.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        greetingCard
                            .apexPadding()
                            .slideUp(delay: 0.05)

                        ringsCard
                            .apexPadding()
                            .slideUp(delay: 0.1)

                        HStack(spacing: Spacing.md) {
                            workoutCard
                            waterCard
                        }
                        .apexPadding()
                        .slideUp(delay: 0.15)

                        if !todaysTasks.isEmpty {
                            aufgabenCard
                                .apexPadding()
                                .slideUp(delay: 0.2)
                        }

                        if last7Weights.count >= 2 {
                            gewichtCard
                                .apexPadding()
                                .slideUp(delay: 0.25)
                        }

                        statsRow
                            .apexPadding()
                            .slideUp(delay: 0.3)

                        if let reminder = nextReminder {
                            naechsteErinnerungCard(reminder)
                                .apexPadding()
                                .slideUp(delay: 0.35)
                        }
                    }
                    .padding(.top, Spacing.sm)
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

    // MARK: - Greeting Card
    private var greetingCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(begruessung)
                    .font(.apexCallout)
                    .foregroundStyle(.apexTextSecondary)
                Text(profile?.name.isEmpty == false ? profile!.name : "Athlet")
                    .font(.apexLargeTitle)
                    .foregroundStyle(.apexTextPrimary)
                Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.apexCallout)
                    .foregroundStyle(.apexTextTertiary)
            }
            Spacer()
            // Streak badge
            VStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.apexOrange)
                    .glowEffect(color: .apexOrange, radius: 6)
                Text("\(sessionsThisWeek)")
                    .font(.apexNumber)
                    .foregroundStyle(.apexTextPrimary)
                Text("Workouts")
                    .font(.apexCaption)
                    .foregroundStyle(.apexTextTertiary)
            }
        }
    }

    private var begruessung: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<10:  return "Guten Morgen,"
        case 10..<12: return "Guten Vormittag,"
        case 12..<14: return "Mahlzeit,"
        case 14..<18: return "Guten Nachmittag,"
        case 18..<22: return "Guten Abend,"
        default:      return "Gute Nacht,"
        }
    }

    // MARK: - Rings Card
    private var ringsCard: some View {
        let calGoal  = Double(profile?.calorieGoal ?? AppConfiguration.defaultCalorieGoal)
        let proGoal  = Double(profile?.proteinGoal ?? AppConfiguration.defaultProteinGoal)
        let waterGoal = Double(profile?.waterGoalMl ?? AppConfiguration.defaultWaterGoalMl)
        let calCur   = Double(todayNutrition?.totalCalories ?? 0)
        let proCur   = todayNutrition?.totalProtein ?? 0
        let waterCur = Double(todayNutrition?.waterMl ?? 0)

        return GlassCard {
            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.xl) {
                    ringCell(
                        progress: taskProgress,
                        color: .apexCyan,
                        value: "\(completedToday)/\(todaysTasks.count)",
                        label: "Aufgaben"
                    )
                    ringCell(
                        progress: calGoal > 0 ? calCur / calGoal : 0,
                        color: .apexOrange,
                        value: "\(Int(calCur))",
                        label: "kcal"
                    )
                    ringCell(
                        progress: proGoal > 0 ? proCur / proGoal : 0,
                        color: .apexPurple,
                        value: "\(Int(proCur))g",
                        label: "Protein"
                    )
                    ringCell(
                        progress: waterGoal > 0 ? waterCur / waterGoal : 0,
                        color: .apexBlue,
                        value: "\(Int(waterCur / 1000 * 10) / 10)L",
                        label: "Wasser"
                    )
                }

                // Habit score bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Gewohnheitsscore diese Woche")
                            .font(.apexCaption)
                            .foregroundStyle(.apexTextTertiary)
                        Spacer()
                        Text("\(Int(habitScoreThisWeek * 100))%")
                            .font(.apexCallout)
                            .foregroundStyle(.apexCyan)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.06)).frame(height: 5)
                            Capsule().fill(Color.apexCyan)
                                .frame(width: geo.size.width * habitScoreThisWeek, height: 5)
                                .animation(.easeInOut(duration: 0.8), value: habitScoreThisWeek)
                        }
                    }
                    .frame(height: 5)
                }
            }
        }
    }

    private func ringCell(progress: Double, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            RingProgressView(progress: progress, lineWidth: 8, size: 66, color: color, label: value)
            Text(label)
                .font(.apexCaption)
                .foregroundStyle(.apexTextSecondary)
        }
    }

    // MARK: - Workout Card
    private var workoutCard: some View {
        NavigationLink(destination: TrainingRootView()) {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "dumbbell.fill").foregroundStyle(.apexCyan)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.apexTextTertiary)
                    }
                    if let last = completedSessions.first {
                        Text("Letztes Workout")
                            .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                        Text(last.name)
                            .font(.apexHeadline).foregroundStyle(.apexTextPrimary).lineLimit(1)
                        Text(last.date.relativeFormatted)
                            .font(.apexCaption).foregroundStyle(.apexTextSecondary)
                    } else {
                        Text("Training")
                            .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                        Text("Kein Workout")
                            .font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                        Text("Starte jetzt!")
                            .font(.apexCaption).foregroundStyle(.apexCyan)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Water Card
    private var waterCard: some View {
        let goal = profile?.waterGoalMl ?? AppConfiguration.defaultWaterGoalMl
        let current = todayNutrition?.waterMl ?? 0
        let progress = goal > 0 ? Double(current) / Double(goal) : 0

        return NavigationLink(destination: NutritionRootView()) {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "drop.fill").foregroundStyle(.apexBlue)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.apexTextTertiary)
                    }
                    Text("Wasser")
                        .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                    Text("\(current) ml")
                        .font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08)).frame(height: 5)
                            Capsule().fill(Color.apexBlue)
                                .frame(width: geo.size.width * min(1, progress), height: 5)
                        }
                    }
                    .frame(height: 5)
                    Text("Ziel: \(goal) ml")
                        .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Aufgaben Card
    private var aufgabenCard: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Heutige Aufgaben")
                    .font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                Spacer()
                NavigationLink("Alle") {
                    DayPlannerView()
                }
                .font(.apexCallout)
                .foregroundStyle(.apexCyan)
            }

            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(todaysTasks.prefix(5))) { task in
                        DashboardTaskRow(task: task)
                        if task.id != todaysTasks.prefix(5).last?.id {
                            Divider().background(.white.opacity(0.05)).padding(.leading, 52)
                        }
                    }
                    if todaysTasks.count > 5 {
                        Text("+ \(todaysTasks.count - 5) weitere")
                            .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                            .frame(maxWidth: .infinity).padding(.vertical, Spacing.sm)
                    }
                }
            }
        }
    }

    // MARK: - Gewicht Chart
    private var gewichtCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Gewichtsverlauf")
                        .font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    Spacer()
                    if let latest = bodyEntries.first {
                        Text(String(format: "%.1f kg", latest.weightKg))
                            .font(.apexCallout).foregroundStyle(.apexCyan)
                    }
                }

                Chart(last7Weights) { e in
                    LineMark(
                        x: .value("Datum", e.date, unit: .day),
                        y: .value("kg", e.weightKg)
                    )
                    .foregroundStyle(Color.apexCyan)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Datum", e.date, unit: .day),
                        y: .value("kg", e.weightKg)
                    )
                    .foregroundStyle(LinearGradient(
                        colors: [.apexCyan.opacity(0.25), .clear],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 70)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 2)) { val in
                        AxisValueLabel {
                            if let d = val.as(Date.self) {
                                Text(d.formatted(.dateTime.day()))
                                    .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { val in
                        AxisValueLabel {
                            if let d = val.as(Double.self) {
                                Text(String(format: "%.0f", d))
                                    .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: Spacing.md) {
            StatCard(
                icon: "trophy.fill",
                value: "\(sessionsThisWeek)",
                label: "Workouts/Woche",
                accentColor: .apexYellow
            )
            StatCard(
                icon: "scalemass.fill",
                value: bodyEntries.first.map { String(format: "%.1f kg", $0.weightKg) } ?? "–",
                label: "Aktuelles Gewicht",
                accentColor: .apexBlue
            )
        }
    }

    // MARK: - Nächste Erinnerung
    private func naechsteErinnerungCard(_ r: Reminder) -> some View {
        GlassCard {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle().fill(Color.apexOrange.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: r.category.icon).foregroundStyle(.apexOrange)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Nächste Erinnerung")
                        .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                    Text(r.title)
                        .font(.apexBody).foregroundStyle(.apexTextPrimary)
                }
                Spacer()
                Text(r.scheduledTime.timeFormatted)
                    .font(.apexCallout).foregroundStyle(.apexOrange)
            }
        }
    }
}

// MARK: - Dashboard Task Row (compact)
struct DashboardTaskRow: View {
    @Bindable var task: APEXTask

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    task.isCompleted.toggle()
                    task.updatedAt = Date()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.apexCyan : Color.white.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if task.isCompleted {
                        Circle().fill(Color.apexCyan).frame(width: 22, height: 22)
                        Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.black)
                    }
                }
            }
            .buttonStyle(.plain)

            Image(systemName: task.category.icon)
                .font(.caption)
                .foregroundStyle(.apexTextTertiary)
                .frame(width: 16)

            Text(task.title)
                .font(.apexCallout)
                .foregroundStyle(task.isCompleted ? .apexTextTertiary : .apexTextPrimary)
                .strikethrough(task.isCompleted)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
    }
}
