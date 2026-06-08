import SwiftUI
import SwiftData
import Charts

struct TrainingRootView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Sub-navigation
                    TrainingTabBar(selected: $selectedTab)
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.sm)

                    TabView(selection: $selectedTab) {
                        WochenplanView().tag(0)
                        TrainingHistoryView().tag(1)
                        UebungsbiblothekView().tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Training")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: WorkoutSessionEditorView()) {
                        Image(systemName: "plus.circle.fill").foregroundStyle(.apexCyan)
                    }
                }
            }
        }
    }
}

// MARK: - Training Tab Bar
struct TrainingTabBar: View {
    @Binding var selected: Int
    let tabs = ["Wochenplan", "Verlauf", "Übungen"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                Button { withAnimation(.spring(response: 0.3)) { selected = i } } label: {
                    Text(tabs[i])
                        .font(.apexCallout)
                        .foregroundStyle(selected == i ? .black : .apexTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selected == i {
                                Capsule().fill(Color.apexCyan)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background { Capsule().fill(Color.white.opacity(0.08)) }
        .padding(.bottom, Spacing.sm)
    }
}

// MARK: - Wochenplan
struct WochenplanView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var showAddSession = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(Weekday.allCases) { day in
                    WochentagKarte(day: day, sessions: sessionsThisWeek(for: day))
                        .apexPadding()
                }

                APEXButton(title: "Session erstellen", icon: "plus") { showAddSession = true }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xl)
            }
            .padding(.top, Spacing.sm)
        }
        .sheet(isPresented: $showAddSession) { WorkoutSessionEditorView() }
    }

    private func sessionsThisWeek(for day: Weekday) -> [WorkoutSession] {
        let weekStart = Calendar.current.startOfWeek(for: Date())
        return sessions.filter { s in
            s.date >= weekStart && s.date.weekday == day
        }
    }
}

struct WochentagKarte: View {
    var day: Weekday
    var sessions: [WorkoutSession]
    @State private var showSession = false
    @State private var selectedSession: WorkoutSession?

    private var isToday: Bool { Weekday.today == day }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(day.fullName)
                            .font(.apexHeadline)
                            .foregroundStyle(isToday ? .apexCyan : .apexTextPrimary)
                        if sessions.isEmpty {
                            Text("Ruhetag")
                                .font(.apexCallout).foregroundStyle(.apexTextTertiary)
                        } else {
                            Text("\(sessions.count) Session\(sessions.count > 1 ? "s" : "")")
                                .font(.apexCallout).foregroundStyle(.apexTextSecondary)
                        }
                    }
                    Spacer()
                    if isToday {
                        Text("HEUTE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(Color.apexCyan))
                    }
                }

                if !sessions.isEmpty {
                    ForEach(sessions) { s in
                        Button {
                            selectedSession = s
                            showSession = true
                        } label: {
                            HStack {
                                Image(systemName: s.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(s.isCompleted ? .apexGreen : .apexCyan)
                                Text(s.name)
                                    .font(.apexCallout).foregroundStyle(.apexTextPrimary)
                                Spacer()
                                Text("\(s.exercises.count) Übungen")
                                    .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                                Image(systemName: "chevron.right")
                                    .font(.caption).foregroundStyle(.apexTextTertiary)
                            }
                            .padding(Spacing.sm)
                            .background {
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .fill(Color.white.opacity(0.04))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(item: $selectedSession) { s in ActiveWorkoutView(session: s) }
    }
}

// MARK: - Training History
struct TrainingHistoryView: View {
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.date, order: .reverse
    ) private var completedSessions: [WorkoutSession]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                if completedSessions.isEmpty {
                    emptyState
                } else {
                    // Weekly volume chart
                    wochenVolumenChart
                        .apexPadding()

                    ForEach(completedSessions) { session in
                        NavigationLink(destination: WorkoutSummaryView(session: session)) {
                            HistorySessionCard(session: session)
                        }
                        .buttonStyle(.plain)
                        .apexPadding()
                    }
                }
            }
            .padding(.top, Spacing.sm)
            .padding(.bottom, 80)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "dumbbell").font(.system(size: 50)).foregroundStyle(.apexTextTertiary)
            Text("Noch kein Training").font(.apexTitle2).foregroundStyle(.apexTextPrimary)
            Text("Starte dein erstes Workout!").font(.apexBody).foregroundStyle(.apexTextSecondary)
        }
        .padding(.top, 80)
    }

    private var wochenVolumenChart: some View {
        let weeklyData = last8WeeksVolume()
        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Wöchentliches Volumen")
                    .font(.apexHeadline).foregroundStyle(.apexTextPrimary)

                Chart(weeklyData, id: \.week) { d in
                    BarMark(
                        x: .value("Woche", d.week),
                        y: .value("Volumen", d.volume)
                    )
                    .foregroundStyle(Color.apexCyan.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 100)
                .chartXAxis {
                    AxisMarks { val in
                        AxisValueLabel {
                            if let s = val.as(String.self) {
                                Text(s).font(.apexCaption).foregroundStyle(.apexTextTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { val in
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                Text(String(format: "%.0f", v)).font(.apexCaption).foregroundStyle(.apexTextTertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func last8WeeksVolume() -> [(week: String, volume: Double)] {
        let cal = Calendar.current
        return (0..<8).reversed().map { offset -> (String, Double) in
            let weekStart = cal.date(byAdding: .weekOfYear, value: -offset, to: cal.startOfWeek(for: Date()))!
            let weekEnd   = cal.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            let vol = completedSessions.filter { $0.date >= weekStart && $0.date < weekEnd }
                .reduce(0.0) { $0 + $1.totalVolume }
            let label = "KW\(cal.component(.weekOfYear, from: weekStart))"
            return (label, vol)
        }
    }
}

struct HistorySessionCard: View {
    var session: WorkoutSession

    var body: some View {
        GlassCard {
            HStack(spacing: Spacing.md) {
                // Date badge
                VStack(spacing: 2) {
                    Text(session.date.formatted(.dateTime.day()))
                        .font(.apexTitle2).foregroundStyle(.apexCyan)
                    Text(session.date.formatted(.dateTime.month(.abbreviated)))
                        .font(.apexCaption).foregroundStyle(.apexTextSecondary)
                }
                .frame(width: 40)

                Divider().background(.white.opacity(0.1)).frame(height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.name).font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    HStack(spacing: Spacing.sm) {
                        Label(String(format: "%.0f kg", session.totalVolume), systemImage: "scalemass.fill")
                        Label("\(session.exercises.count) Übungen", systemImage: "list.bullet")
                        if let dur = session.durationSeconds {
                            Label(dur.durationFormatted, systemImage: "clock.fill")
                        }
                    }
                    .font(.apexCaption)
                    .foregroundStyle(.apexTextSecondary)
                }

                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.apexTextTertiary)
            }
        }
    }
}

// MARK: - Übungsbibliothek
struct UebungsbiblothekView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    private var allExercises: [(name: String, group: MuscleGroup, pr: Double)] {
        var exerciseMap: [String: (group: MuscleGroup, maxWeight: Double)] = [:]
        for session in sessions {
            for exercise in session.exercises {
                let maxW = exercise.sets.filter(\.isCompleted).map(\.weightKg).max() ?? 0
                if let existing = exerciseMap[exercise.name] {
                    if maxW > existing.maxWeight {
                        exerciseMap[exercise.name] = (exercise.muscleGroup, maxW)
                    }
                } else {
                    exerciseMap[exercise.name] = (exercise.muscleGroup, maxW)
                }
            }
        }
        return exerciseMap.map { (name: $0.key, group: $0.value.group, pr: $0.value.maxWeight) }
            .sorted { $0.name < $1.name }
    }

    @State private var searchText = ""
    @State private var filterGroup: MuscleGroup? = nil

    private var filtered: [(name: String, group: MuscleGroup, pr: Double)] {
        allExercises.filter { e in
            (searchText.isEmpty || e.name.localizedCaseInsensitiveContains(searchText)) &&
            (filterGroup == nil || e.group == filterGroup)
        }
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.apexTextTertiary)
                TextField("Übung suchen…", text: $searchText)
                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
            }
            .padding(Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(.ultraThinMaterial)
                    .overlay { RoundedRectangle(cornerRadius: Radius.md).stroke(Color.white.opacity(0.08), lineWidth: 1) }
            }
            .padding(.horizontal, Spacing.md)

            // Muscle filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    filterChip(label: "Alle", isSelected: filterGroup == nil) { filterGroup = nil }
                    ForEach(MuscleGroup.allCases, id: \.self) { g in
                        filterChip(label: g.displayName, isSelected: filterGroup == g) { filterGroup = g }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }

            ScrollView {
                LazyVStack(spacing: Spacing.xs) {
                    if filtered.isEmpty {
                        Text("Keine Übungen gefunden")
                            .font(.apexBody).foregroundStyle(.apexTextTertiary)
                            .padding(.top, 40)
                    } else {
                        ForEach(filtered, id: \.name) { ex in
                            NavigationLink(destination: ExerciseProgressView(exerciseName: ex.name, muscleGroup: ex.group)) {
                                GlassCard(padding: Spacing.sm) {
                                    HStack(spacing: Spacing.md) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: Radius.sm)
                                                .fill(Color.apexCyan.opacity(0.12))
                                                .frame(width: 38, height: 38)
                                            Image(systemName: ex.group.icon)
                                                .font(.callout).foregroundStyle(.apexCyan)
                                        }
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(ex.name).font(.apexBody).foregroundStyle(.apexTextPrimary)
                                            Text(ex.group.displayName).font(.apexCaption).foregroundStyle(.apexTextSecondary)
                                        }
                                        Spacer()
                                        if ex.pr > 0 {
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("PR")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundStyle(.black)
                                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                                    .background(Capsule().fill(Color.apexYellow))
                                                Text("\(Int(ex.pr)) kg")
                                                    .font(.apexCallout).foregroundStyle(.apexYellow)
                                            }
                                        }
                                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.apexTextTertiary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, Spacing.md)
                        }
                    }
                }
                .padding(.top, Spacing.xs)
                .padding(.bottom, 80)
            }
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.apexCallout)
                .foregroundStyle(isSelected ? .black : .apexTextSecondary)
                .padding(.horizontal, Spacing.md).padding(.vertical, 7)
                .background(Capsule().fill(isSelected ? Color.apexCyan : Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Progress
struct ExerciseProgressView: View {
    var exerciseName: String
    var muscleGroup: MuscleGroup
    @Query(sort: \WorkoutSession.date) private var sessions: [WorkoutSession]

    private var progressData: [(date: Date, weight: Double)] {
        var data: [(Date, Double)] = []
        for s in sessions {
            for ex in s.exercises where ex.name == exerciseName {
                if let maxW = ex.sets.filter(\.isCompleted).map(\.weightKg).max(), maxW > 0 {
                    data.append((s.date, maxW))
                }
            }
        }
        return data.sorted { $0.0 < $1.0 }
    }

    var body: some View {
        ZStack {
            Color.apexBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Spacing.md) {
                    // PR Card
                    if let pr = progressData.map(\.weight).max() {
                        AccentGlassCard {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Persönlicher Rekord")
                                        .font(.apexCaption).foregroundStyle(.apexTextSecondary)
                                    Text("\(Int(pr)) kg")
                                        .font(.system(size: 42, weight: .black, design: .rounded))
                                        .foregroundStyle(.apexYellow)
                                        .glowEffect(color: .apexYellow, radius: 6)
                                }
                                Spacer()
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.apexYellow.opacity(0.3))
                            }
                        }
                        .apexPadding()
                    }

                    // Progress chart
                    if progressData.count >= 2 {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Gewichtsverlauf")
                                    .font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                                Chart(progressData, id: \.date) { d in
                                    LineMark(x: .value("Datum", d.date), y: .value("kg", d.weight))
                                        .foregroundStyle(Color.apexCyan).interpolationMethod(.catmullRom)
                                    PointMark(x: .value("Datum", d.date), y: .value("kg", d.weight))
                                        .foregroundStyle(Color.apexCyan).symbolSize(40)
                                }
                                .frame(height: 180)
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .month)) { val in
                                        AxisValueLabel {
                                            if let d = val.as(Date.self) {
                                                Text(d.formatted(.dateTime.month(.abbreviated)))
                                                    .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .apexPadding()
                    }

                    // Sessions list
                    GlassCard(padding: 0) {
                        VStack(spacing: 0) {
                            Text("Sessions")
                                .font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(Spacing.md)
                            Divider().background(.white.opacity(0.06))
                            ForEach(progressData.reversed(), id: \.date) { d in
                                HStack {
                                    Text(d.date.shortFormatted)
                                        .font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                    Spacer()
                                    Text("\(Int(d.weight)) kg")
                                        .font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                                }
                                .padding(.horizontal, Spacing.md).padding(.vertical, 10)
                            }
                        }
                    }
                    .apexPadding()
                }
                .padding(.top, Spacing.md).padding(.bottom, 80)
            }
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.large)
    }
}
