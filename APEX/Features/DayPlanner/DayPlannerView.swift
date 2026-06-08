import SwiftUI
import SwiftData

struct DayPlannerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DaySection.sortOrder) private var sections: [DaySection]
    @State private var selectedDate = Date()
    @State private var showAddTask = false
    @State private var showAddSection = false
    @State private var selectedSection: DaySection?
    @State private var editTask: APEXTask?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Wochenkalender
                    WeekCalendarStrip(selectedDate: $selectedDate)
                        .padding(.vertical, Spacing.sm)
                        .background(.ultraThinMaterial)

                    // Tagesübersicht
                    tagesfortschritt
                        .apexPadding()
                        .padding(.top, Spacing.sm)

                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(sections) { section in
                                DaySectionCard(
                                    section: section,
                                    selectedDate: selectedDate,
                                    onAddTask: {
                                        selectedSection = section
                                        showAddTask = true
                                    },
                                    onEditTask: { task in
                                        editTask = task
                                    }
                                )
                                .apexPadding()
                            }

                            neuerBereichButton
                                .padding(.horizontal, Spacing.md)
                        }
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Tagesplan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.sm) {
                        NavigationLink(destination: KalenderView()) {
                            Image(systemName: "calendar").foregroundStyle(.apexCyan)
                        }
                        Button { showAddSection = true } label: {
                            Image(systemName: "plus.circle.fill").foregroundStyle(.apexCyan)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                if let s = selectedSection {
                    TaskEditorView(section: s, date: selectedDate)
                }
            }
            .sheet(item: $editTask) { task in
                TaskEditorView(section: task.section ?? sections.first!, date: selectedDate, existingTask: task)
            }
            .sheet(isPresented: $showAddSection) {
                SectionEditorView()
            }
            .onAppear {
                if sections.isEmpty { createDefaultSections() }
            }
        }
    }

    // MARK: - Tagesfortschritt
    private var tagesfortschritt: some View {
        let dayTasks = allTasksForDate(selectedDate)
        let done = dayTasks.filter(\.isCompleted).count
        let total = dayTasks.count
        let progress: Double = total > 0 ? Double(done) / Double(total) : 0

        return GlassCard(padding: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                SmallRingView(progress: progress, color: .apexCyan, size: 44, lineWidth: 5)

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDate.isSameDay(as: Date()) ? "Heute" : selectedDate.formatted(.dateTime.weekday(.wide).day().month()))
                        .font(.apexCallout).foregroundStyle(.apexTextSecondary)
                    Text(total == 0 ? "Keine Aufgaben" : "\(done) von \(total) erledigt")
                        .font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                }

                Spacer()

                // Kategorie-Schnellübersicht
                HStack(spacing: 6) {
                    categoryBadge(category: .supplement, tasks: dayTasks)
                    categoryBadge(category: .skincare, tasks: dayTasks)
                    categoryBadge(category: .training, tasks: dayTasks)
                }
            }
        }
    }

    private func categoryBadge(category: TaskCategory, tasks: [APEXTask]) -> some View {
        let filtered = tasks.filter { $0.category == category }
        guard !filtered.isEmpty else { return AnyView(EmptyView()) }
        let done = filtered.filter(\.isCompleted).count
        let allDone = done == filtered.count

        return AnyView(
            VStack(spacing: 2) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(allDone ? .apexGreen : .apexTextTertiary)
                Text("\(done)/\(filtered.count)")
                    .font(.system(size: 8))
                    .foregroundStyle(.apexTextTertiary)
            }
        )
    }

    private func allTasksForDate(_ date: Date) -> [APEXTask] {
        sections.flatMap { $0.tasks }.filter {
            $0.date.isSameDay(as: date) ||
            ($0.isRepeating && $0.repeatDays.contains(date.weekday ?? .monday))
        }
    }

    private var neuerBereichButton: some View {
        Button { showAddSection = true } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Bereich hinzufügen")
            }
            .font(.apexBody).foregroundStyle(.apexCyan)
            .frame(maxWidth: .infinity).padding(Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Color.apexCyan.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
            }
        }
        .buttonStyle(.plain)
    }

    private func createDefaultSections() {
        for sd in AppConfiguration.defaultSections {
            context.insert(DaySection(name: sd.name, icon: sd.icon, sortOrder: sd.sortOrder, colorHex: sd.colorHex))
        }
        try? context.save()
    }
}

// MARK: - DaySectionCard
struct DaySectionCard: View {
    @Environment(\.modelContext) private var context
    @Bindable var section: DaySection
    var selectedDate: Date
    var onAddTask: () -> Void
    var onEditTask: (APEXTask) -> Void

    @State private var isExpanded = true
    @State private var showEditSection = false

    private var tasksForDate: [APEXTask] {
        section.tasks
            .filter {
                $0.date.isSameDay(as: selectedDate) ||
                ($0.isRepeating && $0.repeatDays.contains(selectedDate.weekday ?? .monday))
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var completedCount: Int { tasksForDate.filter(\.isCompleted).count }
    private var totalCount: Int { tasksForDate.count }

    var body: some View {
        GlassCard(padding: 0) {
            VStack(spacing: 0) {
                // Header
                Button {
                    withAnimation(.spring(response: 0.35)) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: section.colorHex).opacity(0.18))
                                .frame(width: 32, height: 32)
                            Image(systemName: section.icon)
                                .font(.callout)
                                .foregroundStyle(Color(hex: section.colorHex))
                        }
                        Text(section.name)
                            .font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                        Spacer()
                        if totalCount > 0 {
                            Text("\(completedCount)/\(totalCount)")
                                .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                        }
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption).foregroundStyle(.apexTextTertiary)
                    }
                    .padding(Spacing.md)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Bearbeiten") { showEditSection = true }
                    Button("Aufgabe hinzufügen", action: onAddTask)
                    Divider()
                    Button("Löschen", role: .destructive) { context.delete(section) }
                }

                if isExpanded {
                    Divider().background(.white.opacity(0.05))

                    if tasksForDate.isEmpty {
                        Button(action: onAddTask) {
                            HStack {
                                Image(systemName: "plus.circle").font(.callout).foregroundStyle(.apexCyan.opacity(0.6))
                                Text("Aufgabe hinzufügen")
                                    .font(.apexCallout).foregroundStyle(.apexTextTertiary)
                                Spacer()
                            }
                            .padding(Spacing.md)
                        }
                        .buttonStyle(.plain)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(tasksForDate) { task in
                                TaskRow(
                                    task: task,
                                    onDelete: { context.delete(task) },
                                    onEdit: { onEditTask(task) }
                                )
                                .padding(.horizontal, Spacing.md)
                                if task.id != tasksForDate.last?.id {
                                    Divider().background(.white.opacity(0.04)).padding(.leading, 56)
                                }
                            }
                            Button(action: onAddTask) {
                                HStack {
                                    Image(systemName: "plus").font(.caption).foregroundStyle(.apexCyan.opacity(0.7))
                                    Text("Aufgabe hinzufügen")
                                        .font(.apexCaption).foregroundStyle(.apexCyan.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSection) { SectionEditorView(section: section) }
    }
}
