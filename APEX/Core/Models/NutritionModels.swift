import Foundation
import SwiftData

@Model
final class DayNutrition {
    var id: UUID
    var date: Date
    var waterMl: Int
    var calorieGoal: Int
    var proteinGoal: Int
    var carbGoal: Int
    var fatGoal: Int

    @Relationship(deleteRule: .cascade, inverse: \Meal.dayNutrition)
    var meals: [Meal] = []

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        waterMl: Int = 0,
        calorieGoal: Int = AppConfiguration.defaultCalorieGoal,
        proteinGoal: Int = AppConfiguration.defaultProteinGoal,
        carbGoal: Int = AppConfiguration.defaultCarbGoal,
        fatGoal: Int = AppConfiguration.defaultFatGoal
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.waterMl = waterMl
        self.calorieGoal = calorieGoal
        self.proteinGoal = proteinGoal
        self.carbGoal = carbGoal
        self.fatGoal = fatGoal
    }

    var totalCalories: Int { meals.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { meals.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double { meals.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double { meals.reduce(0) { $0 + $1.fat } }

    var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(1.0, Double(totalCalories) / Double(calorieGoal))
    }

    var proteinProgress: Double {
        guard proteinGoal > 0 else { return 0 }
        return min(1.0, totalProtein / Double(proteinGoal))
    }

    var waterProgress: Double {
        let profile_goal = AppConfiguration.defaultWaterGoalMl
        guard profile_goal > 0 else { return 0 }
        return min(1.0, Double(waterMl) / Double(profile_goal))
    }
}

@Model
final class Meal {
    var id: UUID
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var isAIEstimate: Bool
    var timestamp: Date
    var mealTypeRaw: String
    var notes: String

    var dayNutrition: DayNutrition?

    init(
        id: UUID = UUID(),
        name: String,
        calories: Int = 0,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0,
        isAIEstimate: Bool = false,
        timestamp: Date = Date(),
        mealType: MealType = .snack,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.isAIEstimate = isAIEstimate
        self.timestamp = timestamp
        self.mealTypeRaw = mealType.rawValue
        self.notes = notes
    }

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .snack }
        set { mealTypeRaw = newValue.rawValue }
    }
}
