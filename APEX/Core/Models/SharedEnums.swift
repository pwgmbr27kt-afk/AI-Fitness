import Foundation

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case monday    = 1
    case tuesday   = 2
    case wednesday = 3
    case thursday  = 4
    case friday    = 5
    case saturday  = 6
    case sunday    = 7

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .monday:    return "Mo"
        case .tuesday:   return "Di"
        case .wednesday: return "Mi"
        case .thursday:  return "Do"
        case .friday:    return "Fr"
        case .saturday:  return "Sa"
        case .sunday:    return "So"
        }
    }

    var fullName: String {
        switch self {
        case .monday:    return "Montag"
        case .tuesday:   return "Dienstag"
        case .wednesday: return "Mittwoch"
        case .thursday:  return "Donnerstag"
        case .friday:    return "Freitag"
        case .saturday:  return "Samstag"
        case .sunday:    return "Sonntag"
        }
    }

    /// Convert from Calendar's weekday (1=Sunday) to Weekday enum
    static func from(calendarWeekday: Int) -> Weekday? {
        // Calendar: 1=Sun, 2=Mon, ..., 7=Sat
        let mapping: [Int: Weekday] = [
            2: .monday, 3: .tuesday, 4: .wednesday,
            5: .thursday, 6: .friday, 7: .saturday, 1: .sunday
        ]
        return mapping[calendarWeekday]
    }

    static var today: Weekday {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: Date())
        return from(calendarWeekday: weekday) ?? .monday
    }
}

enum TaskCategory: String, Codable, CaseIterable {
    case supplement    = "supplement"
    case skincare      = "skincare"
    case training      = "training"
    case essen         = "essen"
    case wasser        = "wasser"
    case dehnen        = "dehnen"
    case schlafroutine = "schlafroutine"
    case custom        = "custom"

    var displayName: String {
        switch self {
        case .supplement:    return "Supplement"
        case .skincare:      return "Skincare"
        case .training:      return "Training"
        case .essen:         return "Essen"
        case .wasser:        return "Wasser"
        case .dehnen:        return "Dehnen"
        case .schlafroutine: return "Schlafroutine"
        case .custom:        return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .supplement:    return "pill.fill"
        case .skincare:      return "drop.fill"
        case .training:      return "dumbbell.fill"
        case .essen:         return "fork.knife"
        case .wasser:        return "drop.circle.fill"
        case .dehnen:        return "figure.flexibility"
        case .schlafroutine: return "moon.fill"
        case .custom:        return "star.fill"
        }
    }
}

enum TaskPriority: Int, Codable, CaseIterable {
    case low    = 0
    case medium = 1
    case high   = 2

    var displayName: String {
        switch self {
        case .low:    return "Niedrig"
        case .medium: return "Mittel"
        case .high:   return "Hoch"
        }
    }

    var color: String {
        switch self {
        case .low:    return "#4CAF50"
        case .medium: return "#FF9800"
        case .high:   return "#F44336"
        }
    }
}

enum ReminderCategory: String, Codable, CaseIterable {
    case supplement = "supplement"
    case skincare   = "skincare"
    case training   = "training"
    case essen      = "essen"
    case wasser     = "wasser"
    case dehnen     = "dehnen"
    case schlaf     = "schlaf"
    case custom     = "custom"

    var displayName: String {
        switch self {
        case .supplement: return "Supplement"
        case .skincare:   return "Skincare"
        case .training:   return "Training"
        case .essen:      return "Essen"
        case .wasser:     return "Wasser"
        case .dehnen:     return "Dehnen"
        case .schlaf:     return "Schlaf"
        case .custom:     return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .supplement: return "pill.fill"
        case .skincare:   return "drop.fill"
        case .training:   return "dumbbell.fill"
        case .essen:      return "fork.knife"
        case .wasser:     return "drop.circle.fill"
        case .dehnen:     return "figure.flexibility"
        case .schlaf:     return "moon.fill"
        case .custom:     return "bell.fill"
        }
    }
}

enum MealType: String, Codable, CaseIterable {
    case fruehstueck  = "fruehstueck"
    case mittagessen  = "mittagessen"
    case abendessen   = "abendessen"
    case snack        = "snack"

    var displayName: String {
        switch self {
        case .fruehstueck: return "Frühstück"
        case .mittagessen: return "Mittagessen"
        case .abendessen:  return "Abendessen"
        case .snack:       return "Snack"
        }
    }

    var icon: String {
        switch self {
        case .fruehstueck: return "sunrise.fill"
        case .mittagessen: return "sun.max.fill"
        case .abendessen:  return "moon.fill"
        case .snack:       return "leaf.fill"
        }
    }
}

enum MuscleGroup: String, Codable, CaseIterable {
    case chest       = "chest"
    case back        = "back"
    case shoulders   = "shoulders"
    case biceps      = "biceps"
    case triceps     = "triceps"
    case legs        = "legs"
    case glutes      = "glutes"
    case core        = "core"
    case calves      = "calves"
    case fullBody    = "full_body"
    case cardio      = "cardio"

    var displayName: String {
        switch self {
        case .chest:     return "Brust"
        case .back:      return "Rücken"
        case .shoulders: return "Schultern"
        case .biceps:    return "Bizeps"
        case .triceps:   return "Trizeps"
        case .legs:      return "Beine"
        case .glutes:    return "Gesäß"
        case .core:      return "Core"
        case .calves:    return "Waden"
        case .fullBody:  return "Ganzkörper"
        case .cardio:    return "Cardio"
        }
    }

    var icon: String {
        switch self {
        case .chest:     return "figure.arms.open"
        case .back:      return "figure.walk"
        case .shoulders: return "figure.arms.open"
        case .biceps:    return "dumbbell.fill"
        case .triceps:   return "dumbbell.fill"
        case .legs:      return "figure.run"
        case .glutes:    return "figure.run"
        case .core:      return "figure.core.training"
        case .calves:    return "figure.run"
        case .fullBody:  return "figure.strengthtraining.functional"
        case .cardio:    return "heart.fill"
        }
    }
}
