import SwiftUI
import SwiftData
import Charts

struct ProgressRootView: View {
    @Query(sort: \BodyEntry.date) private var bodyEntries: [BodyEntry]
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.date
    ) private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]

    @State private var selectedRange: ChartRange = .dreissig
    @State private var showAddEntry = false
    @State private var showBodyAnalysis = false

    enum ChartRange: String, CaseIterable {
        case sieben = "7T"; case dreissig = "30T"; case neunzig = "90T"
        var days: Int {
            switch self { case .sieben: return 7; case .dreissig: return 30; case .neunzig: return 90 }
        }
    }

    private var filteredEntries: [BodyEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedRange.days, to: Date())!
        return bodyEntries.filter { $0.date >= cutoff }
    }

    var body: some View {
        ZStack {
            Color.apexBackground.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    aktuellCard
                        .apexPadding()
                        .slideUp(delay: 0.05)

                    gewichtChartCard
                        .apexPadding()
                        .slideUp(delay: 0.1)

                    bodyFotoSektion
                        .apexPadding()
                        .slideUp(delay: 0.15)

                    bodyInfoCard
                        .apexPadding()
                        .slideUp(delay: 0.2)

                    APEXButton(title: "Messung eintragen", icon: "plus") { showAddEntry = true }
                        .padding(.horizontal, Spacing.md)
                }
                .padding(.top, Spacing.md)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Fortschritt")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.sm) {
                    Button { showBodyAnalysis = true } label: {
                        Image(systemName: "camera.fill").foregroundStyle(.apexCyan)
                    }
                    Button { showAddEntry = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(.apexCyan)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddEntry) { BodyEntryEditorView() }
        .sheet(isPresented: $showBodyAnalysis) { BodyAnalysisView() }
    }

    // MARK: - Aktuell Card
    private var aktuellCard: some View {
        let latest    = bodyEntries.last
        let previous  = bodyEntries.dropLast().last
        let diff      = (latest?.weightKg ?? 0) - (previous?.weightKg ?? 0)
        let hasDiff   = previous != nil && abs(diff) > 0.01

        return AccentGlassCard {
            HStack(spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Aktuelles Gewicht")
                        .font(.apexCaption).foregroundStyle(.apexTextSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(latest.map { String(format: "%.1f", $0.weightKg) } ?? "–")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(.apexTextPrimary)
                        Text("kg").font(.apexHeadline).foregroundStyle(.apexTextSecondary)
                    }
                    if hasDiff {
                        HStack(spacing: 4) {
                            Image(systemName: diff < 0 ? "arrow.down.right" : "arrow.up.right")
                            Text(String(format: "%.1f kg", abs(diff)))
                        }
                        .font(.apexCallout)
                        .foregroundStyle(diff < 0 ? .apexGreen : .apexRed)
                    }
                }
                Spacer()
                if let bf = latest?.bodyFatPercent {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Körperfett")
                            .font(.apexCaption).foregroundStyle(.apexTextSecondary)
                        Text(String(format: "%.1f%%", bf))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.apexCyan)
                    }
                }
            }
        }
    }

    // MARK: - Gewicht Chart
    private var gewichtChartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("Gewichtsverlauf").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    Spacer()
                    // Range picker
                    HStack(spacing: 4) {
                        ForEach(ChartRange.allCases, id: \.self) { r in
                            Button { withAnimation { selectedRange = r } } label: {
                                Text(r.rawValue).font(.apexCaption)
                                    .foregroundStyle(selectedRange == r ? .black : .apexTextSecondary)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Capsule().fill(selectedRange == r ? Color.apexCyan : Color.white.opacity(0.08)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if filteredEntries.count >= 2 {
                    Chart(filteredEntries) { e in
                        LineMark(x: .value("Datum", e.date, unit: .day), y: .value("kg", e.weightKg))
                            .foregroundStyle(Color.apexCyan).interpolationMethod(.catmullRom)
                        AreaMark(x: .value("Datum", e.date, unit: .day), y: .value("kg", e.weightKg))
                            .foregroundStyle(LinearGradient(colors: [.apexCyan.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Datum", e.date, unit: .day), y: .value("kg", e.weightKg))
                            .foregroundStyle(Color.apexCyan).symbolSize(25)
                    }
                    .frame(height: 180)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: selectedRange.days / 6)) { val in
                            AxisValueLabel {
                                if let d = val.as(Date.self) {
                                    Text(d.formatted(.dateTime.day().month(.abbreviated)))
                                        .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing) { val in
                            AxisValueLabel {
                                if let v = val.as(Double.self) {
                                    Text(String(format: "%.0f", v)).font(.apexCaption).foregroundStyle(.apexTextTertiary)
                                }
                            }
                        }
                    }
                } else {
                    Text("Mindestens 2 Einträge für Chart")
                        .font(.apexBody).foregroundStyle(.apexTextTertiary)
                        .frame(height: 80, alignment: .center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Body Fotos
    private var bodyFotoSektion: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Fortschrittsfotos").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                Spacer()
                NavigationLink("Alle") { BodyAnalysisView() }
                    .font(.apexCallout).foregroundStyle(.apexCyan)
            }

            if bodyEntries.filter(\.hasAnyPhoto).isEmpty {
                GlassCard {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 36)).foregroundStyle(.apexTextTertiary)
                        Text("Noch keine Fotos").font(.apexBody).foregroundStyle(.apexTextTertiary)
                        Text("Tippe oben auf die Kamera, um Fotos hinzuzufügen.")
                            .font(.apexCaption).foregroundStyle(.apexTextTertiary).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(Spacing.lg)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(bodyEntries.filter(\.hasAnyPhoto).reversed()) { e in
                            BodyPhotoCard(entry: e)
                                .frame(width: 140)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
        }
    }

    // MARK: - Body Info
    private var bodyInfoCard: some View {
        let entries = bodyEntries.suffix(5).reversed()
        return GlassCard(padding: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text("Messungen").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                    Spacer()
                    Text("Datum / Gewicht / KF%").font(.apexCaption).foregroundStyle(.apexTextTertiary)
                }
                .padding(Spacing.md)
                Divider().background(.white.opacity(0.06))
                ForEach(Array(entries)) { e in
                    HStack {
                        Text(e.date.shortFormatted).font(.apexCallout).foregroundStyle(.apexTextSecondary)
                        Spacer()
                        Text(String(format: "%.1f kg", e.weightKg)).font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                        if let bf = e.bodyFatPercent {
                            Text(String(format: "%.1f%%", bf))
                                .font(.apexCallout).foregroundStyle(.apexCyan)
                                .frame(width: 55, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, Spacing.md).padding(.vertical, 10)
                }
            }
        }
    }
}

// MARK: - Body Entry Editor
struct BodyEntryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var weightKg  = 75.0
    @State private var bodyFat   = ""
    @State private var notes     = ""
    @State private var date      = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Datum").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                DatePicker("", selection: $date, displayedComponents: .date).colorScheme(.dark)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    Text("Gewicht").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                    Spacer()
                                    Text(String(format: "%.1f kg", weightKg))
                                        .font(.apexNumber).foregroundStyle(.apexCyan)
                                }
                                Slider(value: $weightKg, in: 40...200, step: 0.1).tint(.apexCyan)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Körperfett % (optional)").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                TextField("z.B. 14.5", text: $bodyFat)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary).keyboardType(.decimalPad)
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
                    .apexPadding().padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("Messung eintragen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }.foregroundStyle(.apexTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let entry = BodyEntry(date: date, weightKg: weightKg, bodyFatPercent: Double(bodyFat), notes: notes)
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
