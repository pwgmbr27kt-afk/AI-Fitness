import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \WorkoutSession.date) private var sessions: [WorkoutSession]
    @Query(sort: \BodyEntry.date)      private var bodyEntries: [BodyEntry]
    @Query(sort: \DayNutrition.date)   private var nutritionDays: [DayNutrition]
    @Query(sort: \APEXTask.date)       private var tasks: [APEXTask]
    @Query private var profiles: [UserProfile]

    @State private var selectedSection = 0
    private let sections = ["Training", "Ernährung", "Gewicht", "Gewohnheiten"]

    var body: some View {
        ZStack {
            Color.apexBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Section picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(sections.indices, id: \.self) { i in
                            Button { withAnimation(.spring(response: 0.3)) { selectedSection = i } } label: {
                                Text(sections[i])
                                    .font(.apexCallout)
                                    .foregroundStyle(selectedSection == i ? .black : .apexTextSecondary)
                                    .padding(.horizontal, Spacing.md).padding(.vertical, 8)
                                    .background(Capsule().fill(selectedSection == i ? Color.apexCyan : Color.white.opacity(0.08)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
                .padding(.vertical, Spacing.sm)

                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        switch selectedSection {
                        case 0: trainingStats
                        case 1: ernaehrungStats
                        case 2: gewichtStats
                        default: gewohnheitStats
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Statistiken")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Training Stats
    @ViewBuilder
    private var trainingStats: some View {
        // KPIs
        HStack(spacing: Spacing.md) {
            kpiCard(value: "\(sessions.filter { $0.completedAt != nil }.count)", label: "Workouts gesamt", icon: "dumbbell.fill", color: .apexCyan)
            kpiCard(value: "\(sessionsThisMonth)", label: "Diesen Monat", icon: "calendar", color: .apexBlue)
        }
        HStack(spacing: Spacing.md) {
            kpiCard(value: "\(Int(totalVolume / 1000))t", label: "Gesamtvolumen", icon: "scalemass.fill", color: .apexPurple)
            kpiCard(value: "\(longestStreak) Tage", label: "Längste Serie", icon: "flame.fill", color: .apexOrange)
        }

        // Workouts per week (last 12 weeks)
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Workouts pro Woche").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                Chart(workoutsPerWeek, id: \.week) { d in
                    BarMark(x: .value("Woche", d.week), y: .value("Anzahl", d.count))
                        .foregroundStyle(Color.apexCyan.gradient).cornerRadius(4)
                }
                .frame(height: 120).chartXAxis {
                    AxisMarks { val in
                        AxisValueLabel {
                            if let s = val.as(String.self) {
                                Text(s).font(.system(size: 8)).foregroundStyle(.apexTextTertiary)
                            }
                        }
                    }
                }
            }
        }

        // Muscle group distribution
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Muskelgruppen").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                ForEach(muscleGroupStats, id: \.group) { stat in
                    HStack {
                        Image(systemName: stat.group.icon).font(.caption).foregroundStyle(.apexCyan).frame(width: 20)
                        Text(stat.group.displayName).font(.apexCallout).foregroundStyle(.apexTextSecondary)
                        Spacer()
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.06)).frame(height: 6)
                                Capsule().fill(Color.apexCyan)
                                    .frame(width: muscleGroupStats.first.map { geo.size.width * Double(stat.count) / Double($0.count) } ?? 0, height: 6)
                            }
                        }
                        .frame(height: 6).frame(maxWidth: 120)
                        Text("\(stat.count)x").font(.apexCaption).foregroundStyle(.apexTextTertiary).frame(width: 32, alignment: .trailing)
                    }
                }
            }
        }
    }

    // MARK: - Ernährung Stats
    @ViewBuilder
    private var ernaehrungStats: some View {
        HStack(spacing: Spacing.md) {
            let avgCal = avgCalories
            kpiCard(value: "\(avgCal)", label: "Ø Kalorien/Tag", icon: "flame.fill", color: .apexOrange)
            kpiCard(value: "\(nutritionDays.count)", label: "Getrackte Tage", icon: "calendar.badge.checkmark", color: .apexGreen)
        }

        // Kalorien trend (30 Tage)
        let calData = lastNDaysCalories(30)
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Kalorien (30 Tage)").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                Chart(calData, id: \.date) { d in
                    BarMark(x: .value("Datum", d.date, unit: .day), y: .value("kcal", d.calories))
                        .foregroundStyle(Color.apexOrange.gradient).cornerRadius(3)
                    if let goal = profiles.first {
                        RuleMark(y: .value("Ziel", goal.calorieGoal))
                            .foregroundStyle(Color.apexCyan.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    }
                }
                .frame(height: 130).chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { val in
                        AxisValueLabel {
                            if let d = val.as(Date.self) {
                                Text(d.formatted(.dateTime.day().month(.abbreviated)))
                                    .font(.system(size: 8)).foregroundStyle(.apexTextTertiary)
                            }
                        }
                    }
                }
            }
        }

        // Makro Durchschnitt
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Ø Makros pro Tag").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                let avgData = avgMacros
                MacroBar(label: "Protein", current: avgData.protein, goal: Double(profiles.first?.proteinGoal ?? 180), unit: "g", color: .apexCyan)
                MacroBar(label: "Kohlenhydrate", current: avgData.carbs, goal: Double(profiles.first?.carbGoal ?? 280), unit: "g", color: .apexYellow)
                MacroBar(label: "Fett", current: avgData.fat, goal: Double(profiles.first?.fatGoal ?? 80), unit: "g", color: .apexRed)
            }
        }
    }

    // MARK: - Gewicht Stats
    @ViewBuilder
    private var gewichtStats: some View {
        if bodyEntries.count >= 2 {
            HStack(spacing: Spacing.md) {
                let first = bodyEntries.first!
                let last  = bodyEntries.last!
                let diff  = last.weightKg - first.weightKg
                kpiCard(value: String(format: "%.1f kg", last.weightKg), label: "Aktuell", icon: "scalemass.fill", color: .apexCyan)
                kpiCard(value: String(format: "%+.1f kg", diff), label: "Veränderung", icon: diff < 0 ? "arrow.down" : "arrow.up", color: diff < 0 ? .apexGreen : .apexRed)
            }

            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Gewichtsverlauf").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    Chart(bodyEntries) { e in
                        LineMark(x: .value("Datum", e.date), y: .value("kg", e.weightKg))
                            .foregroundStyle(Color.apexCyan).interpolationMethod(.catmullRom)
                        AreaMark(x: .value("Datum", e.date), y: .value("kg", e.weightKg))
                            .foregroundStyle(LinearGradient(colors: [.apexCyan.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 160).chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { val in
                            AxisValueLabel {
                                if let d = val.as(Date.self) {
                                    Text(d.formatted(.dateTime.month(.abbreviated).year()))
                                        .font(.system(size: 8)).foregroundStyle(.apexTextTertiary)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            GlassCard {
                Text("Mindestens 2 Messungen für Statistiken")
                    .font(.apexBody).foregroundStyle(.apexTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .center).padding(Spacing.lg)
            }
        }
    }

    // MARK: - Gewohnheit Stats
    @ViewBuilder
    private var gewohnheitStats: some View {
        let categoryStats = taskCategoryStats
        HStack(spacing: Spacing.md) {
            kpiCard(value: "\(tasks.filter(\.isCompleted).count)", label: "Erledigte Aufgaben", icon: "checkmark.circle.fill", color: .apexGreen)
            kpiCard(value: "\(Int(overallCompletionRate * 100))%", label: "Erledigungsrate", icon: "chart.pie.fill", color: .apexCyan)
        }

        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Nach Kategorie").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                ForEach(categoryStats, id: \.category) { stat in
                    HStack(spacing: Spacing.md) {
                        Image(systemName: stat.category.icon).foregroundStyle(.apexCyan).frame(width: 20)
                        Text(stat.category.displayName).font(.apexCallout).foregroundStyle(.apexTextSecondary)
                        Spacer()
                        Text("\(stat.done)/\(stat.total)").font(.apexCaption).foregroundStyle(.apexTextTertiary)
                        SmallRingView(progress: stat.total > 0 ? Double(stat.done) / Double(stat.total) : 0, color: .apexCyan, size: 28, lineWidth: 3)
                    }
                }
            }
        }
    }

    // MARK: - KPI Card
    private func kpiCard(value: String, label: String, icon: String, color: Color) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Image(systemName: icon).font(.title2).foregroundStyle(color)
                Text(value).font(.apexTitle).foregroundStyle(.apexTextPrimary)
                Text(label).font(.apexCaption).foregroundStyle(.apexTextSecondary).lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Computed Properties
    private var sessionsThisMonth: Int {
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        return sessions.filter { $0.date >= start && $0.completedAt != nil }.count
    }

    private var totalVolume: Double {
        sessions.reduce(0) { $0 + $1.totalVolume }
    }

    private var longestStreak: Int {
        let cal = Calendar.current
        let dates = Set(sessions.filter { $0.completedAt != nil }.map { cal.startOfDay(for: $0.date) }).sorted()
        var maxStreak = 0, current = 0
        var prev: Date? = nil
        for d in dates {
            if let p = prev, cal.dateComponents([.day], from: p, to: d).day == 1 {
                current += 1
            } else {
                current = 1
            }
            maxStreak = max(maxStreak, current)
            prev = d
        }
        return maxStreak
    }

    private var workoutsPerWeek: [(week: String, count: Int)] {
        let cal = Calendar.current
        return (0..<12).reversed().map { offset -> (String, Int) in
            let weekStart = cal.date(byAdding: .weekOfYear, value: -offset, to: cal.startOfWeek(for: Date()))!
            let weekEnd   = cal.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            let count = sessions.filter { $0.date >= weekStart && $0.date < weekEnd && $0.completedAt != nil }.count
            return ("KW\(cal.component(.weekOfYear, from: weekStart))", count)
        }
    }

    private var muscleGroupStats: [(group: MuscleGroup, count: Int)] {
        var dict: [MuscleGroup: Int] = [:]
        for s in sessions where s.completedAt != nil {
            for ex in s.exercises { dict[ex.muscleGroup, default: 0] += 1 }
        }
        return dict.map { (group: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }

    private var avgCalories: Int {
        guard !nutritionDays.isEmpty else { return 0 }
        return nutritionDays.reduce(0) { $0 + $1.totalCalories } / nutritionDays.count
    }

    private func lastNDaysCalories(_ n: Int) -> [(date: Date, calories: Int)] {
        let cal = Calendar.current
        return (0..<n).reversed().map { offset -> (Date, Int) in
            let d = cal.date(byAdding: .day, value: -offset, to: Date())!
            let nut = nutritionDays.first { cal.isDate($0.date, inSameDayAs: d) }
            return (d, nut?.totalCalories ?? 0)
        }
    }

    private var avgMacros: (protein: Double, carbs: Double, fat: Double) {
        guard !nutritionDays.isEmpty else { return (0, 0, 0) }
        let count = Double(nutritionDays.count)
        return (
            nutritionDays.reduce(0.0) { $0 + $1.totalProtein } / count,
            nutritionDays.reduce(0.0) { $0 + $1.totalCarbs } / count,
            nutritionDays.reduce(0.0) { $0 + $1.totalFat } / count
        )
    }

    private var overallCompletionRate: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter(\.isCompleted).count) / Double(tasks.count)
    }

    private var taskCategoryStats: [(category: TaskCategory, done: Int, total: Int)] {
        TaskCategory.allCases.compactMap { cat in
            let filtered = tasks.filter { $0.category == cat }
            guard !filtered.isEmpty else { return nil }
            return (cat, filtered.filter(\.isCompleted).count, filtered.count)
        }
    }
}
