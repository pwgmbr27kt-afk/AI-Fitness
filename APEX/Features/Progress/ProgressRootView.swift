import SwiftUI
import SwiftData
import Charts

struct ProgressRootView: View {
    @Query(sort: \BodyEntry.date) private var bodyEntries: [BodyEntry]
    @Query(sort: \WorkoutSession.date) private var sessions: [WorkoutSession]
    @State private var showAddBodyEntry = false
    @State private var showBodyAnalysis = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                // Weight chart
                weightChartCard
                    .apexPadding()

                // Body photos grid
                bodyPhotosSection
                    .apexPadding()

                // Add entry
                APEXButton(title: "Körperdaten eintragen", icon: "plus") { showAddBodyEntry = true }
                    .padding(.horizontal, Spacing.md)
            }
            .padding(.vertical, Spacing.md)
        }
        .sheet(isPresented: $showAddBodyEntry) { BodyEntryEditorView() }
    }

    private var weightChartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Gewichtsverlauf") {}

                if bodyEntries.count >= 2 {
                    Chart(bodyEntries.suffix(30)) { entry in
                        LineMark(
                            x: .value("Datum", entry.date),
                            y: .value("kg", entry.weightKg)
                        )
                        .foregroundStyle(Color.apexCyan)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Datum", entry.date),
                            y: .value("kg", entry.weightKg)
                        )
                        .foregroundStyle(Color.apexCyan)
                        .symbolSize(30)
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { val in
                            AxisValueLabel {
                                if let date = val.as(Date.self) {
                                    Text(date.formatted(.dateTime.day().month()))
                                        .font(.apexCaption)
                                        .foregroundStyle(.apexTextTertiary)
                                }
                            }
                        }
                    }
                } else {
                    Text("Noch keine Daten")
                        .font(.apexBody)
                        .foregroundStyle(.apexTextTertiary)
                        .frame(height: 80, alignment: .center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var bodyPhotosSection: some View {
        VStack(spacing: Spacing.sm) {
            SectionHeader(title: "Fotos", actionLabel: "Alle") {}
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(bodyEntries.suffix(6).reversed()) { entry in
                        BodyPhotoCard(entry: entry)
                            .frame(width: 140)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }
}

struct BodyEntryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var weightKg = 75.0
    @State private var bodyFat = ""
    @State private var notes = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Datum").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .colorScheme(.dark)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Gewicht").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                HStack {
                                    Text(String(format: "%.1f", weightKg)).font(.apexNumber).foregroundStyle(.apexCyan)
                                    Text("kg").font(.apexHeadline).foregroundStyle(.apexTextSecondary)
                                }
                                Slider(value: $weightKg, in: 40...200, step: 0.1).tint(.apexCyan)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Körperfett % (optional)").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                TextField("z.B. 15", text: $bodyFat)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                                    .keyboardType(.decimalPad)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Notizen").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                TextField("Optional…", text: $notes, axis: .vertical)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                            }
                        }
                    }
                    .apexPadding()
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("Körperdaten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }.foregroundStyle(.apexTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let entry = BodyEntry(
                            date: date,
                            weightKg: weightKg,
                            bodyFatPercent: Double(bodyFat),
                            notes: notes
                        )
                        context.insert(entry)
                        try? context.save()
                        dismiss()
                    }
                    .foregroundStyle(.apexCyan)
                }
            }
        }
    }
}
