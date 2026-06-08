import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Reminder.scheduledTime) private var reminders: [Reminder]
    @StateObject private var notificationService = NotificationService.shared
    @State private var showAddReminder = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                Group {
                    if reminders.isEmpty {
                        emptyState
                    } else {
                        remindersList
                    }
                }
            }
            .navigationTitle("Erinnerungen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddReminder = true
                    } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(.apexCyan)
                    }
                }
            }
            .sheet(isPresented: $showAddReminder) {
                ReminderEditorView()
            }
            .task {
                await notificationService.checkAuthorization()
                if !notificationService.isAuthorized {
                    await notificationService.requestPermission()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(.apexTextTertiary)
            Text("Keine Erinnerungen")
                .font(.apexTitle2)
                .foregroundStyle(.apexTextPrimary)
            Text("Tippe auf + um eine neue Erinnerung hinzuzufügen.")
                .font(.apexBody)
                .foregroundStyle(.apexTextSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var remindersList: some View {
        List {
            ForEach(reminders) { reminder in
                ReminderRow(reminder: reminder)
                    .listRowBackground(Color.apexCard)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            notificationService.cancel(reminder: reminder)
                            context.delete(reminder)
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

struct ReminderRow: View {
    @Bindable var reminder: Reminder
    @StateObject private var notificationService = NotificationService.shared

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.apexCyan.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: reminder.category.icon)
                    .foregroundStyle(.apexCyan)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title).font(.apexBody).foregroundStyle(.apexTextPrimary)
                HStack(spacing: 4) {
                    Text(reminder.scheduledTime.timeFormatted)
                    if !reminder.repeatDays.isEmpty {
                        Text("·")
                        Text(reminder.repeatDays.map(\.shortName).joined(separator: ", "))
                    }
                }
                .font(.apexCaption).foregroundStyle(.apexTextSecondary)
            }

            Spacer()

            Toggle("", isOn: $reminder.isActive)
                .tint(.apexCyan)
                .labelsHidden()
                .onChange(of: reminder.isActive) { _, active in
                    Task {
                        if active {
                            await notificationService.schedule(reminder: reminder)
                        } else {
                            notificationService.cancel(reminder: reminder)
                        }
                    }
                }
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct ReminderEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationService = NotificationService.shared

    var existingReminder: Reminder? = nil

    @State private var title = ""
    @State private var category: ReminderCategory = .custom
    @State private var scheduledTime = Date()
    @State private var selectedDays: Set<Weekday> = Set(Weekday.allCases)
    @State private var priority: TaskPriority = .medium

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Titel").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                TextField("z.B. Vitamine nehmen", text: $title)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Kategorie").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Spacing.sm) {
                                    ForEach(ReminderCategory.allCases, id: \.self) { cat in
                                        let isSelected = category == cat
                                        Button { category = cat } label: {
                                            VStack(spacing: 4) {
                                                Image(systemName: cat.icon).font(.callout)
                                                Text(cat.displayName).font(.system(size: 9)).lineLimit(1)
                                            }
                                            .foregroundStyle(isSelected ? .black : .apexTextSecondary)
                                            .frame(maxWidth: .infinity).padding(.vertical, Spacing.sm)
                                            .background {
                                                RoundedRectangle(cornerRadius: Radius.sm)
                                                    .fill(isSelected ? Color.apexCyan : Color.white.opacity(0.06))
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        GlassCard {
                            DatePicker("Uhrzeit", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                                .colorScheme(.dark).font(.apexBody)
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Wochentage").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                HStack(spacing: Spacing.xs) {
                                    ForEach(Weekday.allCases) { day in
                                        let isOn = selectedDays.contains(day)
                                        Button {
                                            if isOn { selectedDays.remove(day) } else { selectedDays.insert(day) }
                                        } label: {
                                            Text(day.shortName).font(.apexCaption)
                                                .foregroundStyle(isOn ? .black : .apexTextSecondary)
                                                .frame(maxWidth: .infinity).padding(.vertical, 6)
                                                .background {
                                                    RoundedRectangle(cornerRadius: Radius.sm)
                                                        .fill(isOn ? Color.apexCyan : Color.white.opacity(0.06))
                                                }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .apexPadding().padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle(existingReminder == nil ? "Neue Erinnerung" : "Bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }.foregroundStyle(.apexTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .foregroundStyle(title.isNotEmpty ? .apexCyan : .apexTextTertiary)
                        .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let r = existingReminder {
                    title         = r.title
                    category      = r.category
                    scheduledTime = r.scheduledTime
                    selectedDays  = Set(r.repeatDays)
                    priority      = r.priority
                }
            }
        }
    }

    private func save() {
        let reminder: Reminder
        if let r = existingReminder {
            r.title        = title
            r.category     = category
            r.scheduledTime = scheduledTime
            r.repeatDays   = Array(selectedDays)
            r.priority     = priority
            reminder = r
        } else {
            reminder = Reminder(
                title: title,
                category: category,
                scheduledTime: scheduledTime,
                repeatDays: Array(selectedDays),
                priority: priority
            )
            context.insert(reminder)
        }
        try? context.save()
        Task { await notificationService.schedule(reminder: reminder) }
        dismiss()
    }
}
