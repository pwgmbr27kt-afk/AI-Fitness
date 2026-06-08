import SwiftUI
import SwiftData
import Charts

struct NutritionRootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DayNutrition.date, order: .reverse) private var nutritionDays: [DayNutrition]
    @Query private var profiles: [UserProfile]

    @State private var selectedDate = Date()
    @State private var showAddMeal  = false
    @State private var selectedMealType: MealType = .snack

    private var profile: UserProfile? { profiles.first }
    private var todayNutrition: DayNutrition { getOrCreate(for: selectedDate) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    WeekCalendarStrip(selectedDate: $selectedDate)
                        .padding(.vertical, Spacing.sm)
                        .background(.ultraThinMaterial)

                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            makroRinge
                                .apexPadding()
                                .slideUp(delay: 0.05)

                            wasserKarte
                                .apexPadding()
                                .slideUp(delay: 0.1)

                            ForEach(MealType.allCases, id: \.self) { type in
                                MahlzeitTypSektion(
                                    nutrition: todayNutrition,
                                    mealType: type,
                                    onAdd: {
                                        selectedMealType = type
                                        showAddMeal = true
                                    }
                                )
                                .apexPadding()
                                .slideUp(delay: 0.15)
                            }

                            wochenChartKarte
                                .apexPadding()
                                .slideUp(delay: 0.2)
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Ernährung")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddMeal = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(.apexCyan)
                    }
                }
            }
            .sheet(isPresented: $showAddMeal) {
                MealEditorView(nutrition: todayNutrition, defaultType: selectedMealType)
            }
        }
    }

    // MARK: - Makro Ringe
    private var makroRinge: some View {
        let n       = todayNutrition
        let calGoal = Double(n.calorieGoal)
        let proGoal = Double(n.proteinGoal)
        let carbGoal = Double(n.carbGoal)
        let fatGoal = Double(n.fatGoal)

        return GlassCard {
            VStack(spacing: Spacing.lg) {
                HStack(spacing: Spacing.xl) {
                    RingProgressView(
                        progress: calGoal > 0 ? Double(n.totalCalories) / calGoal : 0,
                        lineWidth: 14, size: 100,
                        color: .apexOrange,
                        label: "\(n.totalCalories)",
                        sublabel: "kcal"
                    )
                    VStack(spacing: Spacing.md) {
                        MacroBar(label: "Protein", current: n.totalProtein, goal: proGoal, unit: "g", color: .apexCyan)
                        MacroBar(label: "Kohlenhydrate", current: n.totalCarbs, goal: carbGoal, unit: "g", color: .apexYellow)
                        MacroBar(label: "Fett", current: n.totalFat, goal: fatGoal, unit: "g", color: .apexRed)
                    }
                }
                HStack {
                    Text("Ziel: \(n.calorieGoal) kcal")
                        .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                    Spacer()
                    let remaining = n.calorieGoal - n.totalCalories
                    Text(remaining >= 0 ? "Noch \(remaining) kcal" : "\(abs(remaining)) kcal über Ziel")
                        .font(.apexCaption)
                        .foregroundStyle(remaining >= 0 ? .apexTextTertiary : .apexRed)
                }
            }
        }
    }

    // MARK: - Wasser Karte
    private var wasserKarte: some View {
        let n = todayNutrition
        let goal = profile?.waterGoalMl ?? AppConfiguration.defaultWaterGoalMl
        let progress = goal > 0 ? Double(n.waterMl) / Double(goal) : 0

        return GlassCard {
            VStack(spacing: Spacing.md) {
                HStack {
                    Image(systemName: "drop.fill").foregroundStyle(.apexBlue)
                    Text("Wasser").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    Spacer()
                    Text("\(n.waterMl) / \(goal) ml")
                        .font(.apexCallout).foregroundStyle(.apexTextSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08)).frame(height: 10)
                        Capsule().fill(
                            LinearGradient(colors: [.apexBlue, .apexCyan], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * min(1, progress), height: 10)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                    }
                }
                .frame(height: 10)

                HStack(spacing: Spacing.sm) {
                    ForEach([150, 250, 330, 500], id: \.self) { ml in
                        Button {
                            n.waterMl += ml
                            try? context.save()
                        } label: {
                            Text("+\(ml) ml")
                                .font(.apexCallout).foregroundStyle(.apexBlue)
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(Capsule().fill(Color.apexBlue.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Wochen Chart
    private var wochenChartKarte: some View {
        let data = lastSevenDays()
        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Diese Woche").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                Chart(data, id: \.date) { d in
                    BarMark(
                        x: .value("Tag", d.date, unit: .day),
                        y: .value("kcal", d.calories)
                    )
                    .foregroundStyle(Color.apexOrange.gradient)
                    .cornerRadius(4)

                    if let goal = profile {
                        RuleMark(y: .value("Ziel", goal.calorieGoal))
                            .foregroundStyle(Color.apexCyan.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    }
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { val in
                        AxisValueLabel {
                            if let d = val.as(Date.self) {
                                Text(d.formatted(.dateTime.weekday(.abbreviated)))
                                    .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func lastSevenDays() -> [(date: Date, calories: Int)] {
        (0..<7).map { offset -> (Date, Int) in
            let d = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            let cal = nutritionDays.first { Calendar.current.isDate($0.date, inSameDayAs: d) }
            return (d, cal?.totalCalories ?? 0)
        }
        .reversed()
    }

    private func getOrCreate(for date: Date) -> DayNutrition {
        let dayStart = Calendar.current.startOfDay(for: date)
        if let existing = nutritionDays.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            return existing
        }
        let new = DayNutrition(
            date: dayStart,
            calorieGoal: profile?.calorieGoal ?? AppConfiguration.defaultCalorieGoal,
            proteinGoal: profile?.proteinGoal ?? AppConfiguration.defaultProteinGoal,
            carbGoal:    profile?.carbGoal    ?? AppConfiguration.defaultCarbGoal,
            fatGoal:     profile?.fatGoal     ?? AppConfiguration.defaultFatGoal
        )
        context.insert(new)
        try? context.save()
        return new
    }
}

// MARK: - Mahlzeit Typ Sektion
struct MahlzeitTypSektion: View {
    var nutrition: DayNutrition
    var mealType: MealType
    var onAdd: () -> Void
    @Environment(\.modelContext) private var context
    @State private var editMeal: Meal? = nil

    private var meals: [Meal] {
        nutrition.meals.filter { $0.mealType == mealType }.sorted { $0.timestamp < $1.timestamp }
    }
    private var totalCalories: Int { meals.reduce(0) { $0 + $1.calories } }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: mealType.icon).foregroundStyle(.apexCyan)
                Text(mealType.displayName).font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                Spacer()
                if totalCalories > 0 {
                    Text("\(totalCalories) kcal").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                }
            }

            if meals.isEmpty {
                Button(action: onAdd) {
                    HStack {
                        Image(systemName: "plus").font(.callout)
                        Text("Mahlzeit hinzufügen").font(.apexCallout)
                    }
                    .foregroundStyle(.apexCyan.opacity(0.7))
                    .frame(maxWidth: .infinity).padding(Spacing.sm)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.md)
                            .stroke(Color.apexCyan.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    }
                }
                .buttonStyle(.plain)
            } else {
                GlassCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(meals) { meal in
                            MahlzeitZeile(meal: meal, onEdit: { editMeal = meal }, onDelete: { context.delete(meal) })
                            if meal.id != meals.last?.id {
                                Divider().background(.white.opacity(0.05))
                            }
                        }
                        Button(action: onAdd) {
                            HStack {
                                Image(systemName: "plus.circle").font(.caption).foregroundStyle(.apexCyan.opacity(0.7))
                                Text("Hinzufügen").font(.apexCaption).foregroundStyle(.apexCyan.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Spacing.md)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(item: $editMeal) { meal in
            MealEditorView(nutrition: nutrition, defaultType: mealType, existingMeal: meal)
        }
    }
}

struct MahlzeitZeile: View {
    var meal: Meal
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(meal.name).font(.apexBody).foregroundStyle(.apexTextPrimary).lineLimit(1)
                    if meal.isAIEstimate {
                        Text("KI")
                            .font(.system(size: 8, weight: .bold)).foregroundStyle(.black)
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(Capsule().fill(Color.apexCyan))
                    }
                }
                HStack(spacing: Spacing.sm) {
                    Text("\(Int(meal.protein))g P").foregroundStyle(.apexCyan)
                    Text("\(Int(meal.carbs))g K").foregroundStyle(.apexYellow)
                    Text("\(Int(meal.fat))g F").foregroundStyle(.apexRed)
                }
                .font(.apexCaption)
            }
            Spacer()
            Text("\(meal.calories) kcal").font(.apexCallout).foregroundStyle(.apexTextPrimary)
        }
        .padding(Spacing.md)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) { Label("Löschen", systemImage: "trash") }
            Button(action: onEdit) { Label("Bearbeiten", systemImage: "pencil") }.tint(.apexBlue)
        }
    }
}

// MARK: - Meal Editor (full)
struct MealEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var nutrition: DayNutrition
    var defaultType: MealType
    var existingMeal: Meal? = nil

    @State private var name       = ""
    @State private var calories   = ""
    @State private var protein    = ""
    @State private var carbs      = ""
    @State private var fat        = ""
    @State private var mealType: MealType = .snack
    @State private var showAIEstimate = false
    @State private var isLoadingAI   = false
    @StateObject private var ai      = AIService.shared
    @State private var aiError: String? = nil

    private var isEditing: Bool { existingMeal != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Name").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                TextField("z.B. Hähnchenbrust mit Reis", text: $name)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                            }
                        }

                        // Mahlzeit Typ
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Mahlzeit-Typ").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Spacing.sm) {
                                        ForEach(MealType.allCases, id: \.self) { t in
                                            Button { mealType = t } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: t.icon).font(.caption)
                                                    Text(t.displayName).font(.apexCallout)
                                                }
                                                .foregroundStyle(mealType == t ? .black : .apexTextSecondary)
                                                .padding(.horizontal, Spacing.sm).padding(.vertical, 7)
                                                .background(Capsule().fill(mealType == t ? Color.apexCyan : Color.white.opacity(0.08)))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        // Nährwerte
                        GlassCard {
                            VStack(spacing: Spacing.md) {
                                Text("Nährwerte").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                nährstoffFeld(label: "Kalorien (kcal)", binding: $calories, icon: "flame.fill", color: .apexOrange)
                                Divider().background(.white.opacity(0.08))
                                nährstoffFeld(label: "Protein (g)", binding: $protein, icon: "bolt.fill", color: .apexCyan)
                                Divider().background(.white.opacity(0.08))
                                nährstoffFeld(label: "Kohlenhydrate (g)", binding: $carbs, icon: "leaf.fill", color: .apexYellow)
                                Divider().background(.white.opacity(0.08))
                                nährstoffFeld(label: "Fett (g)", binding: $fat, icon: "drop.fill", color: .apexRed)
                            }
                        }

                        // AI Schnellschätzung
                        if !isEditing {
                            GlassCard {
                                VStack(alignment: .leading, spacing: Spacing.md) {
                                    HStack {
                                        Image(systemName: "brain.head.profile").foregroundStyle(.apexCyan)
                                        Text("KI-Schätzung").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                                        Spacer()
                                        Text("Beta").font(.system(size: 9, weight: .bold)).foregroundStyle(.black)
                                            .padding(.horizontal, 6).padding(.vertical, 3)
                                            .background(Capsule().fill(Color.apexCyan))
                                    }
                                    Text("Nährwerte anhand des Namens schätzen")
                                        .font(.apexCallout).foregroundStyle(.apexTextSecondary)

                                    if let err = aiError {
                                        Text(err).font(.apexCaption).foregroundStyle(.apexRed)
                                    }

                                    APEXButton(
                                        title: isLoadingAI ? "Schätze…" : "Nährwerte schätzen",
                                        icon: "wand.and.stars",
                                        style: .secondary,
                                        isEnabled: name.isNotEmpty && !isLoadingAI
                                    ) {
                                        estimateWithAI()
                                    }
                                }
                            }
                        }
                    }
                    .apexPadding()
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle(isEditing ? "Mahlzeit bearbeiten" : "Mahlzeit hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }.foregroundStyle(.apexTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Speichern" : "Hinzufügen") { save() }
                        .foregroundStyle(name.isNotEmpty ? .apexCyan : .apexTextTertiary)
                        .disabled(name.isEmpty)
                }
            }
            .onAppear {
                mealType = defaultType
                if let m = existingMeal {
                    name     = m.name
                    calories = "\(m.calories)"
                    protein  = "\(Int(m.protein))"
                    carbs    = "\(Int(m.carbs))"
                    fat      = "\(Int(m.fat))"
                    mealType = m.mealType
                }
            }
        }
    }

    private func nährstoffFeld(label: String, binding: Binding<String>, icon: String, color: Color) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 20)
            Text(label).font(.apexBody).foregroundStyle(.apexTextSecondary)
            Spacer()
            TextField("0", text: binding)
                .font(.apexBody).foregroundStyle(.apexTextPrimary)
                .multilineTextAlignment(.trailing).keyboardType(.numberPad)
                .frame(width: 60)
        }
    }

    private func estimateWithAI() {
        guard name.isNotEmpty else { return }
        isLoadingAI = true
        aiError = nil
        Task {
            do {
                let prompt = """
                Schätze die Nährwerte für: "\(name)"
                Antworte NUR mit JSON ohne weiteren Text:
                {"calories":500,"protein":30,"carbs":45,"fat":15}
                Alle Werte als Ganzzahl (kcal/g). Typische Portionsgröße annehmen.
                """
                let messages = [AnthropicMessage(role: "user", content: [.text(prompt)])]
                let response = try await ai.send(systemPrompt: "", messages: messages, maxTokens: 128)
                if let data = response.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Int] {
                    await MainActor.run {
                        calories = "\(json["calories"] ?? 0)"
                        protein  = "\(json["protein"] ?? 0)"
                        carbs    = "\(json["carbs"] ?? 0)"
                        fat      = "\(json["fat"] ?? 0)"
                    }
                }
            } catch {
                await MainActor.run { aiError = error.localizedDescription }
            }
            await MainActor.run { isLoadingAI = false }
        }
    }

    private func save() {
        if let m = existingMeal {
            m.name     = name
            m.calories = Int(calories) ?? 0
            m.protein  = Double(protein) ?? 0
            m.carbs    = Double(carbs) ?? 0
            m.fat      = Double(fat) ?? 0
            m.mealType = mealType
        } else {
            let meal = Meal(
                name: name,
                calories: Int(calories) ?? 0,
                protein: Double(protein) ?? 0,
                carbs: Double(carbs) ?? 0,
                fat: Double(fat) ?? 0,
                isAIEstimate: false,
                mealType: mealType
            )
            context.insert(meal)
            meal.dayNutrition = nutrition
        }
        try? context.save()
        dismiss()
    }
}
