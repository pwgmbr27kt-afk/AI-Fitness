import Foundation
import SwiftData

@Model
final class WorkoutPlan {
    var id: UUID
    var name: String
    var weekdaysRaw: [Int]
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.plan)
    var sessions: [WorkoutSession] = []

    init(
        id: UUID = UUID(),
        name: String,
        weekdays: [Weekday] = [],
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.weekdaysRaw = weekdays.map(\.rawValue)
        self.notes = notes
        self.createdAt = Date()
    }

    var weekdays: [Weekday] {
        get { weekdaysRaw.compactMap { Weekday(rawValue: $0) } }
        set { weekdaysRaw = newValue.map(\.rawValue) }
    }
}

@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var name: String
    var completedAt: Date?
    var notes: String
    var durationSeconds: Int?

    var plan: WorkoutPlan?

    @Relationship(deleteRule: .cascade, inverse: \Exercise.session)
    var exercises: [Exercise] = []

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        name: String,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.notes = notes
    }

    var isCompleted: Bool { completedAt != nil }

    var totalVolume: Double {
        exercises.reduce(0) { acc, ex in
            acc + ex.sets.reduce(0) { s, set in
                s + (set.isCompleted ? Double(set.reps) * set.weightKg : 0)
            }
        }
    }
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var muscleGroupRaw: String
    var notes: String
    var sortOrder: Int

    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet] = []

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup = .fullBody,
        notes: String = "",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.notes = notes
        self.sortOrder = sortOrder
    }

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .fullBody }
        set { muscleGroupRaw = newValue.rawValue }
    }

    var completedSetsCount: Int { sets.filter(\.isCompleted).count }
    var totalSetsCount: Int { sets.count }
}

@Model
final class ExerciseSet {
    var id: UUID
    var reps: Int
    var weightKg: Double
    var isCompleted: Bool
    var rpe: Double?
    var sortOrder: Int

    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        reps: Int = 8,
        weightKg: Double = 0,
        isCompleted: Bool = false,
        rpe: Double? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.reps = reps
        self.weightKg = weightKg
        self.isCompleted = isCompleted
        self.rpe = rpe
        self.sortOrder = sortOrder
    }

    var volume: Double { isCompleted ? Double(reps) * weightKg : 0 }
}
