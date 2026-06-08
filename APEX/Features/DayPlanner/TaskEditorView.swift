import SwiftUI
import SwiftData

struct TaskEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var section: DaySection
    var date: Date
    var existingTask: APEXTask?

    @State private var title = ""
    @State private var notes = ""
    @State private var category: TaskCategory = .custom
    @State private var priority: TaskPriority = .medium
    @State private var isRepeating = false
    @State private var repeatDays: Set<Weekday> = []
    @State private var hasReminder = false
    @State private var reminderTime = Date()

    private var isEditing: Bool { existingTask != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Title
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Titel")
                                    .font(.apexCallout)
                                    .foregroundStyle(.apexTextSecondary)
                                TextField("Aufgabe eingeben…", text: $title, axis: .vertical)
                                    .font(.apexBody)
                                    .foregroundStyle(.apexTextPrimary)
                            }
                        }

                        // Category
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Kategorie")
                                    .font(.apexCallout)
                                    .foregroundStyle(.apexTextSecondary)
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Spacing.sm) {
                                    ForEach(TaskCategory.allCases, id: \.self) { cat in
                                        categoryChip(cat)
                                    }
                                }
                            }
                        }

                        // Priority
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Priorität")
                                    .font(.apexCallout)
                                    .foregroundStyle(.apexTextSecondary)
                                HStack(spacing: Spacing.sm) {
                                    ForEach(TaskPriority.allCases, id: \.self) { p in
                                        priorityChip(p)
                                    }
                                }
                            }
                        }

                        // Repeating
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Toggle(isOn: $isRepeating) {
                                    Label("Wiederholen", systemImage: "arrow.clockwise")
                                        .font(.apexBody)
                                        .foregroundStyle(.apexTextPrimary)
                                }
                                .tint(.apexCyan)

                                if isRepeating {
                                    HStack(spacing: Spacing.xs) {
                                        ForEach(Weekday.allCases) { day in
                                            weekdayToggle(day)
                                        }
                                    }
                                }
                            }
                        }

                        // Reminder
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Toggle(isOn: $hasReminder) {
                                    Label("Erinnerung", systemImage: "bell.fill")
                                        .font(.apexBody)
                                        .foregroundStyle(.apexTextPrimary)
                                }
                                .tint(.apexCyan)

                                if hasReminder {
                                    DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                        .colorScheme(.dark)
                                }
                            }
                        }

                        // Notes
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Notizen")
                                    .font(.apexCallout)
                                    .foregroundStyle(.apexTextSecondary)
                                TextField("Optional…", text: $notes, axis: .vertical)
                                    .font(.apexBody)
                                    .foregroundStyle(.apexTextPrimary)
                                    .lineLimit(3...6)
                            }
                        }
                    }
                    .apexPadding()
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle(isEditing ? "Aufgabe bearbeiten" : "Neue Aufgabe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundStyle(.apexTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Speichern" : "Hinzufügen") { save() }
                        .foregroundStyle(title.isNotEmpty ? .apexCyan : .apexTextTertiary)
                        .disabled(title.isEmpty)
                }
            }
            .onAppear { populate() }
        }
    }

    private func categoryChip(_ cat: TaskCategory) -> some View {
        let isSelected = category == cat
        return Button {
            category = cat
        } label: {
            VStack(spacing: 4) {
                Image(systemName: cat.icon)
                    .font(.callout)
                Text(cat.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .black : .apexTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(isSelected ? Color.apexCyan : Color.white.opacity(0.06))
            }
        }
        .buttonStyle(.plain)
    }

    private func priorityChip(_ p: TaskPriority) -> some View {
        let isSelected = priority == p
        return Button {
            priority = p
        } label: {
            Text(p.displayName)
                .font(.apexCallout)
                .foregroundStyle(isSelected ? .black : .apexTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background {
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(isSelected ? Color(hex: p.color) : Color.white.opacity(0.06))
                }
        }
        .buttonStyle(.plain)
    }

    private func weekdayToggle(_ day: Weekday) -> some View {
        let isOn = repeatDays.contains(day)
        return Button {
            if isOn { repeatDays.remove(day) } else { repeatDays.insert(day) }
        } label: {
            Text(day.shortName)
                .font(.apexCaption)
                .foregroundStyle(isOn ? .black : .apexTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(isOn ? Color.apexCyan : Color.white.opacity(0.06))
                }
        }
        .buttonStyle(.plain)
    }

    private func populate() {
        guard let task = existingTask else { return }
        title       = task.title
        notes       = task.notes
        category    = task.category
        priority    = task.priority
        isRepeating = task.isRepeating
        repeatDays  = Set(task.repeatDays)
        if let rt = task.reminderTime {
            hasReminder  = true
            reminderTime = rt
        }
    }

    private func save() {
        if let task = existingTask {
            task.title        = title
            task.notes        = notes
            task.category     = category
            task.priority     = priority
            task.isRepeating  = isRepeating
            task.repeatDays   = Array(repeatDays)
            task.reminderTime = hasReminder ? reminderTime : nil
            task.updatedAt    = Date()
        } else {
            let task = APEXTask(
                title: title,
                date: date,
                isRepeating: isRepeating,
                repeatDays: Array(repeatDays),
                reminderTime: hasReminder ? reminderTime : nil,
                category: category,
                priority: priority,
                notes: notes,
                section: section
            )
            context.insert(task)
        }
        try? context.save()
        dismiss()
    }
}
