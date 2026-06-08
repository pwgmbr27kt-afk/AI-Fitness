import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule reminder
    func schedule(reminder: Reminder) async {
        guard isAuthorized else { return }
        let center = UNUserNotificationCenter.current()

        // Remove existing
        center.removePendingNotificationRequests(withIdentifiers: [reminder.notificationIdentifier])

        guard reminder.isActive else { return }

        let content = UNMutableNotificationContent()
        content.title = "APEX"
        content.body  = reminder.title
        content.sound = .default
        content.categoryIdentifier = reminder.categoryRaw

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminder.scheduledTime)

        if reminder.repeatDays.isEmpty {
            // One-time, just use the time today
            var components = timeComponents
            components.second = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: reminder.notificationIdentifier,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        } else {
            // Schedule for each repeat day
            for day in reminder.repeatDays {
                var components = timeComponents
                components.weekday = calendarWeekday(for: day)
                components.second  = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let id = "\(reminder.notificationIdentifier)-\(day.rawValue)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }

    func cancel(reminder: Reminder) {
        let center = UNUserNotificationCenter.current()
        let ids = [reminder.notificationIdentifier] + reminder.repeatDays.map {
            "\(reminder.notificationIdentifier)-\($0.rawValue)"
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func scheduleTaskReminder(task: APEXTask) async {
        guard isAuthorized, let reminderTime = task.reminderTime else { return }
        let center = UNUserNotificationCenter.current()
        let id = "task-\(task.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "APEX"
        content.body  = task.title
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func calendarWeekday(for weekday: Weekday) -> Int {
        // Calendar weekday: 1=Sun, 2=Mon ... 7=Sat
        switch weekday {
        case .sunday:    return 1
        case .monday:    return 2
        case .tuesday:   return 3
        case .wednesday: return 4
        case .thursday:  return 5
        case .friday:    return 6
        case .saturday:  return 7
        }
    }
}
