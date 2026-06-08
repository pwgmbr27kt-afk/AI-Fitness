import Foundation
import SwiftData

@Model
final class MobilityRoutine {
    var id: UUID
    var name: String
    var scheduledDaysRaw: [Int]
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MobilityExercise.routine)
    var exercises: [MobilityExercise] = []

    init(
        id: UUID = UUID(),
        name: String,
        scheduledDays: [Weekday] = [],
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.scheduledDaysRaw = scheduledDays.map(\.rawValue)
        self.notes = notes
        self.createdAt = Date()
    }

    var scheduledDays: [Weekday] {
        get { scheduledDaysRaw.compactMap { Weekday(rawValue: $0) } }
        set { scheduledDaysRaw = newValue.map(\.rawValue) }
    }

    var totalDurationSeconds: Int {
        exercises.reduce(0) { $0 + ($1.durationSeconds * $1.sets) }
    }
}

@Model
final class MobilityExercise {
    var id: UUID
    var name: String
    var durationSeconds: Int
    var sets: Int
    var exerciseDescription: String
    var videoURL: String?
    var sortOrder: Int

    var routine: MobilityRoutine?

    init(
        id: UUID = UUID(),
        name: String,
        durationSeconds: Int = 30,
        sets: Int = 3,
        description: String = "",
        videoURL: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.sets = sets
        self.exerciseDescription = description
        self.videoURL = videoURL
        self.sortOrder = sortOrder
    }
}
