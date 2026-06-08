import SwiftUI

struct WeekCalendarStrip: View {
    @Binding var selectedDate: Date
    var accentColor: Color = .apexCyan

    @State private var visibleWeekStart: Date = Date().startOfWeek

    private let calendar = Calendar.current
    private let dayWidth: CGFloat = 52

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(daysInMonth, id: \.self) { day in
                        dayCell(day)
                            .id(day)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .onAppear {
                proxy.scrollTo(calendar.startOfDay(for: selectedDate), anchor: .center)
            }
            .onChange(of: selectedDate) { _, new in
                withAnimation {
                    proxy.scrollTo(calendar.startOfDay(for: new), anchor: .center)
                }
            }
        }
    }

    private var daysInMonth: [Date] {
        let start = visibleWeekStart.addingTimeInterval(-30 * 86400)
        return (0..<90).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
                .map { calendar.startOfDay(for: $0) }
        }
    }

    @ViewBuilder
    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday    = calendar.isDateInToday(date)

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 6) {
                Text(dayName(date))
                    .font(.apexCaption)
                    .foregroundStyle(isSelected ? .black : .apexTextSecondary)

                Text(dayNumber(date))
                    .font(.apexHeadline)
                    .foregroundStyle(isSelected ? .black : (isToday ? accentColor : .apexTextPrimary))

                // Dot for today
                Circle()
                    .fill(isToday && !isSelected ? accentColor : .clear)
                    .frame(width: 4, height: 4)
            }
            .frame(width: dayWidth, height: 72)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(accentColor)
                } else if isToday {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(accentColor.opacity(0.4), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func dayName(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
    }

    private func dayNumber(_ date: Date) -> String {
        date.formatted(.dateTime.day())
    }
}

extension Date {
    var startOfWeek: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        components.weekday = 2  // Monday
        return calendar.date(from: components) ?? self
    }
}
