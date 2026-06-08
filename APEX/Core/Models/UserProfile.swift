import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var birthDate: Date
    var heightCm: Double
    var weightKg: Double
    var goalType: GoalType
    var activityLevel: ActivityLevel
    var calorieGoal: Int
    var proteinGoal: Int
    var carbGoal: Int
    var fatGoal: Int
    var waterGoalMl: Int
    var accentColorHex: String
    var onboardingCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
        heightCm: Double = 175,
        weightKg: Double = 75,
        goalType: GoalType = .maintain,
        activityLevel: ActivityLevel = .moderate,
        calorieGoal: Int = AppConfiguration.defaultCalorieGoal,
        proteinGoal: Int = AppConfiguration.defaultProteinGoal,
        carbGoal: Int = AppConfiguration.defaultCarbGoal,
        fatGoal: Int = AppConfiguration.defaultFatGoal,
        waterGoalMl: Int = AppConfiguration.defaultWaterGoalMl,
        accentColorHex: String = "#00D4FF",
        onboardingCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.goalType = goalType
        self.activityLevel = activityLevel
        self.calorieGoal = calorieGoal
        self.proteinGoal = proteinGoal
        self.carbGoal = carbGoal
        self.fatGoal = fatGoal
        self.waterGoalMl = waterGoalMl
        self.accentColorHex = accentColorHex
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }
}

enum GoalType: String, Codable, CaseIterable {
    case bulk     = "bulk"
    case cut      = "cut"
    case recomp   = "recomp"
    case maintain = "maintain"

    var displayName: String {
        switch self {
        case .bulk:     return "Aufbauen"
        case .cut:      return "Definieren"
        case .recomp:   return "Rekomposition"
        case .maintain: return "Halten"
        }
    }

    var icon: String {
        switch self {
        case .bulk:     return "arrow.up.circle.fill"
        case .cut:      return "flame.fill"
        case .recomp:   return "arrow.triangle.2.circlepath"
        case .maintain: return "equal.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .bulk:     return "Muskelmasse aufbauen, Kalorienüberschuss"
        case .cut:      return "Körperfett reduzieren, Kaloriendefizit"
        case .recomp:   return "Gleichzeitig Muskeln aufbauen und Fett abbauen"
        case .maintain: return "Gewicht halten, Kalorienbilanz ausgeglichen"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary   = "sedentary"
    case light       = "light"
    case moderate    = "moderate"
    case active      = "active"
    case veryActive  = "very_active"

    var displayName: String {
        switch self {
        case .sedentary:  return "Sitzend (kaum Sport)"
        case .light:      return "Leicht aktiv (1–3x/Woche)"
        case .moderate:   return "Mäßig aktiv (3–5x/Woche)"
        case .active:     return "Sehr aktiv (6–7x/Woche)"
        case .veryActive: return "Extrem aktiv (täglich intensiv)"
        }
    }

    /// PAL (Physical Activity Level) multiplier
    var tdeeMultiplier: Double {
        switch self {
        case .sedentary:  return 1.2
        case .light:      return 1.375
        case .moderate:   return 1.55
        case .active:     return 1.725
        case .veryActive: return 1.9
        }
    }
}

// MARK: - TDEE Calculator
extension UserProfile {
    /// Mifflin-St Jeor BMR then apply PAL multiplier
    func calculateTDEE() -> Int {
        // Assume male formula as default; for more accuracy a sex field can be added later
        let bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        return Int(bmr * activityLevel.tdeeMultiplier)
    }

    /// Suggested goals based on goal type
    func suggestedGoals() -> (calories: Int, protein: Int, carbs: Int, fat: Int, water: Int) {
        let tdee = calculateTDEE()
        var calories: Int
        let protein = Int(weightKg * 2.0)   // 2g per kg bodyweight

        switch goalType {
        case .bulk:     calories = tdee + 300
        case .cut:      calories = tdee - 500
        case .recomp:   calories = tdee
        case .maintain: calories = tdee
        }

        let proteinCals = protein * 4
        let fatCals     = Int(Double(calories) * 0.25)
        let fat         = fatCals / 9
        let carbCals    = calories - proteinCals - fatCals
        let carbs       = max(0, carbCals / 4)
        let water       = Int(weightKg * 35)   // 35ml per kg

        return (calories, protein, carbs, fat, water)
    }
}
