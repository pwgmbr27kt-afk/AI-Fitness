import SwiftUI
import SwiftData

struct KalenderView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \APEXTask.date) private var allTasks: [APEXTask]
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.date
    ) private var sessions: [WorkoutSession]
    @Query(sort: \DayNutrition.date) private var nutritionDays: [DayNutrition]

    @State private var displayedMonth = Date()
    @State private var selectedDate: Date? = nil

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            Color.apexBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Month navigation
                monthHeader
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)

                // Weekday labels
                weekdayLabels
                    .padding(.horizontal, Spacing.md)

                // Calendar grid
                calendarGrid
                    .padding(.horizontal, Spacing.md)

                Divider().background(.white.opacity(0.08))

                // Day detail
                if let date = selectedDate {
                    dayDetail(date)
                } else {
                    monthSummary
                }
            }
        }
        .navigationTitle("Kalender")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Month Header
    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.left").font(.title3).foregroundStyle(.apexCyan)
            }
            Spacer()
            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.apexTitle2).foregroundStyle(.apexTextPrimary)
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.right").font(.title3).foregroundStyle(.apexCyan)
            }
        }
    }

    // MARK: - Weekday Labels
    private var weekdayLabels: some View {
        HStack(spacing: 0) {
            ForEach(["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"], id: \.self) { d in
                Text(d)
                    .font(.apexCaption)
                    .foregroundStyle(.apexTextTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    DayCell(
                        date: day,
                        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false,
                        isToday: calendar.isDateInToday(day),
                        hasWorkout: hasWorkout(on: day),
                        hasAllTasksDone: allTasksDone(on: day),
                        taskCount: taskCount(on: day)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedDate.map({ calendar.isDate($0, inSameDayAs: day) }) == true {
                                selectedDate = nil
                            } else {
                                selectedDate = day
                            }
                        }
                    }
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Day Detail
    private func dayDetail(_ date: Date) -> some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                    .font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                // Workout
                let daySessions = sessions.filter { calendar.isDate($0.date, inSameDayAs: date) }
                if !daySessions.isEmpty {
                    ForEach(daySessions) { s in
                        GlassCard {
                            HStack {
                                Image(systemName: "dumbbell.fill").foregroundStyle(.apexCyan)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(s.name).font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                                    Text(String(format: "%.0f kg Volumen · %d Übungen", s.totalVolume, s.exercises.count))
                                        .font(.apexCaption).foregroundStyle(.apexTextSecondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.apexGreen)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }

                // Nutrition
                let dayNut = nutritionDays.first { calendar.isDate($0.date, inSameDayAs: date) }
                if let n = dayNut {
                    GlassCard {
                        HStack(spacing: Spacing.lg) {
                            macroMini(value: "\(n.totalCalories)", label: "kcal", color: .apexOrange)
                            macroMini(value: "\(Int(n.totalProtein))g", label: "Protein", color: .apexPurple)
                            macroMini(value: "\(Int(n.totalCarbs))g", label: "Kohlenhydr.", color: .apexYellow)
                            macroMini(value: "\(Int(n.totalFat))g", label: "Fett", color: .apexRed)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }

                // Tasks
                let dayTasks = allTasks.filter {
                    $0.date.isSameDay(as: date) ||
                    ($0.isRepeating && $0.repeatDays.contains(date.weekday ?? .monday))
                }
                if !dayTasks.isEmpty {
                    GlassCard(padding: 0) {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Aufgaben")
                                    .font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                Spacer()
                                Text("\(dayTasks.filter(\.isCompleted).count)/\(dayTasks.count)")
                                    .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                            }
                            .padding(Spacing.md)
                            Divider().background(.white.opacity(0.06))
                            ForEach(dayTasks) { task in
                                HStack(spacing: Spacing.md) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(task.isCompleted ? .apexGreen : .apexTextTertiary)
                                    Image(systemName: task.category.icon).font(.caption).foregroundStyle(.apexTextTertiary)
                                    Text(task.title).font(.apexCallout)
                                        .foregroundStyle(task.isCompleted ? .apexTextTertiary : .apexTextPrimary)
                                        .strikethrough(task.isCompleted)
                                    Spacer()
                                }
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.bottom, 100)
        }
    }

    private func macroMini(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.apexCallout).foregroundStyle(color)
            Text(label).font(.apexCaption).foregroundStyle(.apexTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Month Summary
    private var monthSummary: some View {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let monthEnd   = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        let monthSessions = sessions.filter { $0.date >= monthStart && $0.date < monthEnd }

        return ScrollView {
            VStack(spacing: Spacing.md) {
                Text("Monatsübersicht")
                    .font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                HStack(spacing: Spacing.md) {
                    summaryCell(icon: "dumbbell.fill", value: "\(monthSessions.count)", label: "Workouts", color: .apexCyan)
                    summaryCell(icon: "scalemass.fill", value: "\(volumeThisMonth(monthStart: monthStart, end: monthEnd))", label: "Gesamt kg", color: .apexBlue)
                    summaryCell(icon: "flame.fill", value: "\(activeDaysThisMonth(monthStart: monthStart, end: monthEnd))", label: "Aktive Tage", color: .apexOrange)
                }
                .padding(.horizontal, Spacing.md)
            }
            .padding(.bottom, 100)
        }
    }

    private func summaryCell(icon: String, value: String, label: String, color: Color) -> some View {
        GlassCard {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title3).foregroundStyle(color)
                Text(value).font(.apexTitle2).foregroundStyle(.apexTextPrimary)
                Text(label).font(.apexCaption).foregroundStyle(.apexTextSecondary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers
    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }
        // Weekday of first day (adjust for Monday start)
        var weekday = calendar.component(.weekday, from: first) - 2
        if weekday < 0 { weekday += 7 }

        var days: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: first))
        }
        // Fill to complete last row
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func hasWorkout(on date: Date) -> Bool {
        sessions.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func allTasksDone(on date: Date) -> Bool {
        let tasks = allTasks.filter { $0.date.isSameDay(as: date) }
        return !tasks.isEmpty && tasks.allSatisfy(\.isCompleted)
    }

    private func taskCount(on date: Date) -> Int {
        allTasks.filter { $0.date.isSameDay(as: date) }.count
    }

    private func volumeThisMonth(monthStart: Date, end: Date) -> Int {
        let s = sessions.filter { $0.date >= monthStart && $0.date < end }
        return Int(s.reduce(0) { $0 + $1.totalVolume })
    }

    private func activeDaysThisMonth(monthStart: Date, end: Date) -> Int {
        let s = sessions.filter { $0.date >= monthStart && $0.date < end }
        let days = Set(s.map { calendar.startOfDay(for: $0.date) })
        return days.count
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasWorkout: Bool
    let hasAllTasksDone: Bool
    let taskCount: Int

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 3) {
            Text("\(calendar.component(.day, from: date))")
                .font(isToday ? .apexHeadline : .apexCallout)
                .foregroundStyle(isSelected ? .black : (isToday ? .apexCyan : .apexTextPrimary))
                .frame(width: 32, height: 32)
                .background {
                    if isSelected {
                        Circle().fill(Color.apexCyan)
                    } else if isToday {
                        Circle().stroke(Color.apexCyan, lineWidth: 1.5)
                    }
                }

            // Indicators
            HStack(spacing: 3) {
                if hasWorkout {
                    Circle().fill(Color.apexCyan).frame(width: 4, height: 4)
                }
                if hasAllTasksDone && taskCount > 0 {
                    Circle().fill(Color.apexGreen).frame(width: 4, height: 4)
                } else if taskCount > 0 {
                    Circle().fill(Color.apexOrange).frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(height: 52)
    }
}
