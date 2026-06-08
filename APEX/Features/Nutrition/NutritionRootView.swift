import SwiftUI
import SwiftData

struct NutritionRootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DayNutrition.date, order: .reverse) private var nutritionDays: [DayNutrition]
    @Query private var profiles: [UserProfile]
    @State private var selectedDate = Date()
    @State private var showAddMeal = false
    @State private var showWaterSheet = false

    private var profile: UserProfile? { profiles.first }

    private var todayNutrition: DayNutrition {
        if let existing = nutritionDays.first(where: { $0.date.isSameDay(as: selectedDate) }) {
            return existing
        }
        let new = DayNutrition(
            date: selectedDate,
            calorieGoal: profile?.calorieGoal ?? AppConfiguration.defaultCalorieGoal,
            proteinGoal: profile?.proteinGoal ?? AppConfiguration.defaultProteinGoal,
            carbGoal: profile?.carbGoal ?? AppConfiguration.defaultCarbGoal,
            fatGoal: profile?.fatGoal ?? AppConfiguration.defaultFatGoal
        )
        context.insert(new)
        try? context.save()
        return new
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        // Date strip
                        WeekCalendarStrip(selectedDate: $selectedDate)
                            .padding(.vertical, Spacing.sm)

                        // Macro rings
                        macroRingsCard
                            .apexPadding()

                        // Water tracker
                        waterCard
                            .apexPadding()

                        // Meals by type
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            MealTypeSection(
                                nutrition: todayNutrition,
                                mealType: mealType,
                                onAddMeal: { showAddMeal = true }
                            )
                            .apexPadding()
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Ernährung")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddMeal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.apexCyan)
                    }
                }
            }
            .sheet(isPresented: $showAddMeal) {
                MealEditorView(nutrition: todayNutrition)
            }
        }
    }

    private var macroRingsCard: some View {
        let n = todayNutrition
        let calGoal = Double(n.calorieGoal)
        let proGoal = Double(n.proteinGoal)
        let carbGoal = Double(n.carbGoal)
        let fatGoal = Double(n.fatGoal)

        return GlassCard {
            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.lg) {
                    RingProgressView(
                        progress: calGoal > 0 ? Double(n.totalCalories) / calGoal : 0,
                        lineWidth: 12,
                        size: 90,
                        color: .apexOrange,
                        label: "\(n.totalCalories)",
                        sublabel: "kcal"
                    )
                    VStack(spacing: Spacing.sm) {
                        MacroBar(label: "Protein", current: n.totalProtein, goal: proGoal, unit: "g", color: .apexCyan)
                        MacroBar(label: "Kohlenhydrate", current: n.totalCarbs, goal: carbGoal, unit: "g", color: .apexYellow)
                        MacroBar(label: "Fett", current: n.totalFat, goal: fatGoal, unit: "g", color: .apexOrange)
                    }
                }
                HStack {
                    Text("Ziel: \(n.calorieGoal) kcal")
                        .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                    Spacer()
                    Text("Verbleibend: \(max(0, n.calorieGoal - n.totalCalories)) kcal")
                        .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                }
            }
        }
    }

    private var waterCard: some View {
        let n = todayNutrition
        let waterGoal = profile?.waterGoalMl ?? AppConfiguration.defaultWaterGoalMl

        return GlassCard {
            VStack(spacing: Spacing.md) {
                HStack {
                    Image(systemName: "drop.fill").foregroundStyle(.apexBlue)
                    Text("Wasser").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    Spacer()
                    Text("\(n.waterMl) / \(waterGoal) ml").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08)).frame(height: 8)
                        Capsule().fill(Color.apexBlue)
                            .frame(width: geo.size.width * min(1, Double(n.waterMl) / Double(waterGoal)), height: 8)
                            .animation(.easeInOut(duration: 0.5), value: n.waterMl)
                    }
                }
                .frame(height: 8)

                // Quick add buttons
                HStack(spacing: Spacing.sm) {
                    ForEach([150, 250, 330, 500], id: \.self) { ml in
                        Button {
                            n.waterMl += ml
                            try? context.save()
                        } label: {
                            Text("+\(ml)ml")
                                .font(.apexCallout)
                                .foregroundStyle(.apexBlue)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.apexBlue.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Meal Type Section
struct MealTypeSection: View {
    var nutrition: DayNutrition
    var mealType: MealType
    var onAddMeal: () -> Void
    @Environment(\.modelContext) private var context

    private var meals: [Meal] {
        nutrition.meals
            .filter { $0.mealType == mealType }
            .sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: mealType.icon).foregroundStyle(.apexCyan)
                Text(mealType.displayName).font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                Spacer()
                Text("\(meals.reduce(0) { $0 + $1.calories }) kcal")
                    .font(.apexCallout).foregroundStyle(.apexTextSecondary)
            }

            if meals.isEmpty {
                Button(action: onAddMeal) {
                    HStack {
                        Image(systemName: "plus").font(.callout)
                        Text("Mahlzeit hinzufügen").font(.apexCallout)
                    }
                    .foregroundStyle(.apexCyan.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.sm)
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
                            MealRow(meal: meal, onDelete: { context.delete(meal) })
                            if meal.id != meals.last?.id {
                                Divider().background(.white.opacity(0.06))
                            }
                        }
                        Button(action: onAddMeal) {
                            HStack {
                                Image(systemName: "plus.circle").font(.callout)
                                Text("Hinzufügen").font(.apexCallout)
                            }
                            .foregroundStyle(.apexCyan.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Spacing.md)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct MealRow: View {
    var meal: Meal
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(meal.name).font(.apexBody).foregroundStyle(.apexTextPrimary)
                    if meal.isAIEstimate {
                        Text("KI")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(Capsule().fill(Color.apexCyan))
                    }
                }
                Text("\(Int(meal.protein))g P · \(Int(meal.carbs))g K · \(Int(meal.fat))g F")
                    .font(.apexCaption).foregroundStyle(.apexTextSecondary)
            }
            Spacer()
            Text("\(meal.calories) kcal").font(.apexCallout).foregroundStyle(.apexTextPrimary)
        }
        .padding(Spacing.md)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
            }
        }
    }
}

// MARK: - Meal Editor
struct MealEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var nutrition: DayNutrition

    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var mealType: MealType = .snack

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Name").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                TextField("z.B. Hähnchenbrust", text: $name)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Mahlzeit-Typ").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                Picker("", selection: $mealType) {
                                    ForEach(MealType.allCases, id: \.self) { t in
                                        Text(t.displayName).tag(t)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        GlassCard {
                            VStack(spacing: Spacing.sm) {
                                macroField(label: "Kalorien (kcal)", binding: $calories, placeholder: "0")
                                Divider().background(.white.opacity(0.1))
                                macroField(label: "Protein (g)", binding: $protein, placeholder: "0")
                                Divider().background(.white.opacity(0.1))
                                macroField(label: "Kohlenhydrate (g)", binding: $carbs, placeholder: "0")
                                Divider().background(.white.opacity(0.1))
                                macroField(label: "Fett (g)", binding: $fat, placeholder: "0")
                            }
                        }
                    }
                    .apexPadding()
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("Mahlzeit hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }.foregroundStyle(.apexTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") { save() }
                        .foregroundStyle(name.isNotEmpty ? .apexCyan : .apexTextTertiary)
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func macroField(label: String, binding: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label).font(.apexBody).foregroundStyle(.apexTextSecondary)
            Spacer()
            TextField(placeholder, text: binding)
                .font(.apexBody).foregroundStyle(.apexTextPrimary)
                .multilineTextAlignment(.trailing)
                .keyboardType(.numberPad)
                .frame(width: 70)
        }
    }

    private func save() {
        let meal = Meal(
            name: name,
            calories: Int(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            mealType: mealType
        )
        context.insert(meal)
        meal.dayNutrition = nutrition
        try? context.save()
        dismiss()
    }
}
