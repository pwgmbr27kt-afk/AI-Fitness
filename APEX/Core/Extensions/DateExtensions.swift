import Foundation

extension Date {
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    var weekday: Weekday? {
        Weekday.from(calendarWeekday: Calendar.current.component(.weekday, from: self))
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }

    var shortFormatted: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    var timeFormatted: String {
        formatted(date: .omitted, time: .shortened)
    }

    var relativeFormatted: String {
        if isToday     { return "Heute" }
        if isYesterday { return "Gestern" }
        return shortFormatted
    }
}

extension Calendar {
    func startOfWeek(for date: Date, startingOn weekday: Int = 2) -> Date {
        var components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = weekday
        return self.date(from: components) ?? date
    }
}
