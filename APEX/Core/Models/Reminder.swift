import Foundation
import SwiftData

@Model
final class Reminder {
    var id: UUID
    var title: String
    var categoryRaw: String
    var scheduledTime: Date
    var repeatDaysRaw: [Int]
    var isActive: Bool
    var priorityRaw: Int
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        category: ReminderCategory = .custom,
        scheduledTime: Date = Date(),
        repeatDays: [Weekday] = Weekday.allCases,
        isActive: Bool = true,
        priority: TaskPriority = .medium,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.scheduledTime = scheduledTime
        self.repeatDaysRaw = repeatDays.map(\.rawValue)
        self.isActive = isActive
        self.priorityRaw = priority.rawValue
        self.notes = notes
        self.createdAt = Date()
    }

    var category: ReminderCategory {
        get { ReminderCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }

    var repeatDays: [Weekday] {
        get { repeatDaysRaw.compactMap { Weekday(rawValue: $0) } }
        set { repeatDaysRaw = newValue.map(\.rawValue) }
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    var notificationIdentifier: String { "reminder-\(id.uuidString)" }
}
