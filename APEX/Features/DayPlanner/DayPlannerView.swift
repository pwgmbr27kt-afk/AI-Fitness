import SwiftUI
import SwiftData

struct DayPlannerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DaySection.sortOrder) private var sections: [DaySection]
    @State private var selectedDate = Date()
    @State private var showAddTask = false
    @State private var showAddSection = false
    @State private var selectedSection: DaySection?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Week calendar
                    WeekCalendarStrip(selectedDate: $selectedDate)
                        .padding(.vertical, Spacing.sm)
                        .background(.ultraThinMaterial)

                    // Sections list
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(sections) { section in
                                DaySectionCard(
                                    section: section,
                                    selectedDate: selectedDate,
                                    onAddTask: {
                                        selectedSection = section
                                        showAddTask = true
                                    }
                                )
                                .apexPadding()
                            }

                            // Add section button
                            Button {
                                showAddSection = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Bereich hinzufügen")
                                }
                                .font(.apexBody)
                                .foregroundStyle(.apexCyan)
                                .frame(maxWidth: .infinity)
                                .padding(Spacing.md)
                                .background {
                                    RoundedRectangle(cornerRadius: Radius.lg)
                                        .stroke(Color.apexCyan.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                        .padding(.top, Spacing.md)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Tagesplaner")
            .sheet(isPresented: $showAddTask) {
                if let section = selectedSection {
                    TaskEditorView(section: section, date: selectedDate)
                }
            }
            .sheet(isPresented: $showAddSection) {
                SectionEditorView()
            }
            .onAppear {
                if sections.isEmpty { createDefaultSections() }
            }
        }
    }

    private func createDefaultSections() {
        for sectionData in AppConfiguration.defaultSections {
            let section = DaySection(
                name: sectionData.name,
                icon: sectionData.icon,
                sortOrder: sectionData.sortOrder,
                colorHex: sectionData.colorHex
            )
            context.insert(section)
        }
        try? context.save()
    }
}

// MARK: - Day Section Card
struct DaySectionCard: View {
    @Environment(\.modelContext) private var context
    @Bindable var section: DaySection
    var selectedDate: Date
    var onAddTask: () -> Void

    @State private var isExpanded = true
    @State private var showEditSection = false

    private var tasksForDate: [APEXTask] {
        section.tasks
            .filter { $0.date.isSameDay(as: selectedDate) || ($0.isRepeating && $0.repeatDays.contains(selectedDate.weekday ?? .monday)) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        GlassCard(padding: 0) {
            VStack(spacing: 0) {
                // Section header
                Button {
                    withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: section.icon)
                            .font(.callout)
                            .foregroundStyle(Color(hex: section.colorHex))
                            .frame(width: 24)

                        Text(section.name)
                            .font(.apexHeadline)
                            .foregroundStyle(.apexTextPrimary)

                        Spacer()

                        Text("\(tasksForDate.filter(\.isCompleted).count)/\(tasksForDate.count)")
                            .font(.apexCaption)
                            .foregroundStyle(.apexTextTertiary)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.apexTextTertiary)
                    }
                    .padding(Spacing.md)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Bearbeiten") { showEditSection = true }
                    Button("Aufgabe hinzufügen") { onAddTask() }
                    Divider()
                    Button("Löschen", role: .destructive) { context.delete(section) }
                }

                if isExpanded {
                    Divider().background(.white.opacity(0.06))

                    if tasksForDate.isEmpty {
                        HStack {
                            Text("Keine Aufgaben")
                                .font(.apexCaption)
                                .foregroundStyle(.apexTextTertiary)
                            Spacer()
                            Button(action: onAddTask) {
                                Image(systemName: "plus")
                                    .font(.callout)
                                    .foregroundStyle(.apexCyan)
                            }
                        }
                        .padding(Spacing.md)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(tasksForDate) { task in
                                TaskRow(task: task, onDelete: { context.delete(task) })
                                    .padding(.horizontal, Spacing.md)
                                if task.id != tasksForDate.last?.id {
                                    Divider().background(.white.opacity(0.05)).padding(.leading, 60)
                                }
                            }

                            // Add task button
                            Button(action: onAddTask) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .font(.callout)
                                    Text("Aufgabe hinzufügen")
                                        .font(.apexCallout)
                                }
                                .foregroundStyle(.apexCyan.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSection) {
            SectionEditorView(section: section)
        }
    }
}
