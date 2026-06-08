import Foundation
import SwiftData

@Model
final class APEXTask {
    var id: UUID
    var title: String
    var date: Date
    var isCompleted: Bool
    var isRepeating: Bool
    var repeatDaysRaw: [Int]
    var reminderTime: Date?
    var categoryRaw: String
    var priorityRaw: Int
    var notes: String
    var streakCount: Int
    var lastCompletedDate: Date?
    var createdAt: Date
    var updatedAt: Date

    var section: DaySection?

    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        isCompleted: Bool = false,
        isRepeating: Bool = false,
        repeatDays: [Weekday] = [],
        reminderTime: Date? = nil,
        category: TaskCategory = .custom,
        priority: TaskPriority = .medium,
        notes: String = "",
        section: DaySection? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.isCompleted = isCompleted
        self.isRepeating = isRepeating
        self.repeatDaysRaw = repeatDays.map(\.rawValue)
        self.reminderTime = reminderTime
        self.categoryRaw = category.rawValue
        self.priorityRaw = priority.rawValue
        self.notes = notes
        self.section = section
        self.streakCount = 0
        self.lastCompletedDate = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    var repeatDays: [Weekday] {
        get { repeatDaysRaw.compactMap { Weekday(rawValue: $0) } }
        set { repeatDaysRaw = newValue.map(\.rawValue) }
    }
}
