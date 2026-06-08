import SwiftUI
import SwiftData
import PhotosUI

struct BodyAnalysisView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BodyEntry.date, order: .reverse) private var entries: [BodyEntry]

    @State private var selectedEntry: BodyEntry?
    @State private var showAddEntry  = false
    @State private var compareMode   = false
    @State private var compareEntry1: BodyEntry?
    @State private var compareEntry2: BodyEntry?

    var body: some View {
        ZStack {
            Color.apexBackground.ignoresSafeArea()
            if entries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        // Compare button
                        if entries.count >= 2 {
                            Button {
                                withAnimation { compareMode.toggle() }
                                if compareMode {
                                    compareEntry1 = entries.first
                                    compareEntry2 = entries.dropFirst().first
                                }
                            } label: {
                                HStack {
                                    Image(systemName: compareMode ? "xmark.circle" : "arrow.left.arrow.right")
                                    Text(compareMode ? "Vergleich beenden" : "Fotos vergleichen")
                                }
                                .font(.apexCallout)
                                .foregroundStyle(compareMode ? .apexRed : .apexCyan)
                                .frame(maxWidth: .infinity).padding(Spacing.sm)
                                .background {
                                    RoundedRectangle(cornerRadius: Radius.lg)
                                        .stroke((compareMode ? Color.apexRed : Color.apexCyan).opacity(0.3), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, Spacing.md)
                        }

                        // Compare view
                        if compareMode, let e1 = compareEntry1, let e2 = compareEntry2 {
                            VergleichView(entry1: e1, entry2: e2,
                                          allEntries: entries,
                                          onChangeEntry1: { compareEntry1 = $0 },
                                          onChangeEntry2: { compareEntry2 = $0 })
                                .apexPadding()
                        }

                        // Photo grid
                        if !compareMode {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                                ForEach(entries) { entry in
                                    FotoEintragKarte(entry: entry) {
                                        selectedEntry = entry
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                    }
                    .padding(.top, Spacing.md).padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Körperanalyse")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddEntry = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(.apexCyan)
                }
            }
        }
        .sheet(isPresented: $showAddEntry) { FotoEintragEditor() }
        .sheet(item: $selectedEntry) { entry in FotoDetailView(entry: entry) }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "person.crop.rectangle.stack.fill")
                .font(.system(size: 70)).foregroundStyle(.apexTextTertiary)
            VStack(spacing: Spacing.sm) {
                Text("Keine Fotos").font(.apexTitle).foregroundStyle(.apexTextPrimary)
                Text("Füge Körperfotos hinzu, um deinen Fortschritt\nvisuell zu verfolgen und KI-Analysen zu erhalten.")
                    .font(.apexBody).foregroundStyle(.apexTextSecondary).multilineTextAlignment(.center)
            }
            APEXButton(title: "Erste Fotos hinzufügen", icon: "camera.fill") { showAddEntry = true }
                .padding(.horizontal, Spacing.xl)
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Foto Eintrag Karte
struct FotoEintragKarte: View {
    var entry: BodyEntry
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            GlassCard(padding: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Photo
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(Color.apexSurface).frame(height: 120)
                        if let data = entry.photoFront, let img = UIImage(data: data) {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(height: 120).clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 36)).foregroundStyle(.apexTextTertiary)
                        }
                        // AI badge
                        if entry.aiAnalysis != nil {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "brain.head.profile")
                                        .font(.caption).foregroundStyle(.white)
                                        .padding(5)
                                        .background(Circle().fill(Color.apexCyan))
                                }
                                Spacer()
                            }
                            .padding(6)
                        }
                    }
                    Text(entry.date.formatted(.dateTime.day().month(.abbreviated).year()))
                        .font(.apexCaption).foregroundStyle(.apexTextSecondary)
                    Text(String(format: "%.1f kg", entry.weightKg))
                        .font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Foto Detail View
struct FotoDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: BodyEntry

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var fotoTyp: FotoTyp = .front
    @State private var isAnalyzing = false
    @State private var showAnalysis = false
    @StateObject private var ai = AIService.shared

    enum FotoTyp: String, CaseIterable {
        case front = "Vorne"; case side = "Seite"; case back = "Rücken"
        var icon: String {
            switch self { case .front: return "person.fill"; case .side: return "person.fill.viewfinder"; case .back: return "figure.walk" }
        }
    }

    private var currentPhotoData: Data? {
        switch fotoTyp {
        case .front: return entry.photoFront
        case .side:  return entry.photoSide
        case .back:  return entry.photoBack
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        // Foto type selector
                        HStack(spacing: Spacing.sm) {
                            ForEach(FotoTyp.allCases, id: \.self) { typ in
                                Button { fotoTyp = typ } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: typ.icon).font(.caption)
                                        Text(typ.rawValue).font(.apexCallout)
                                    }
                                    .foregroundStyle(fotoTyp == typ ? .black : .apexTextSecondary)
                                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(fotoTyp == typ ? Color.apexCyan : Color.white.opacity(0.08)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .apexPadding()

                        // Photo display
                        ZStack {
                            RoundedRectangle(cornerRadius: Radius.xl).fill(Color.apexSurface).frame(height: 320)
                            if let data = currentPhotoData, let img = UIImage(data: data) {
                                Image(uiImage: img).resizable().scaledToFit()
                                    .frame(height: 320).clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                            } else {
                                VStack(spacing: Spacing.sm) {
                                    Image(systemName: "camera.fill").font(.system(size: 50)).foregroundStyle(.apexTextTertiary)
                                    Text("Kein Foto").font(.apexBody).foregroundStyle(.apexTextTertiary)
                                }
                            }
                        }
                        .apexPadding()

                        // Photo picker
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text(currentPhotoData == nil ? "Foto hinzufügen" : "Foto ändern")
                            }
                            .font(.apexBody).foregroundStyle(.apexCyan)
                            .frame(maxWidth: .infinity).padding(Spacing.md)
                            .background { RoundedRectangle(cornerRadius: Radius.lg).fill(Color.apexCyan.opacity(0.1)) }
                        }
                        .padding(.horizontal, Spacing.md)

                        // Messungen
                        GlassCard {
                            VStack(spacing: Spacing.sm) {
                                HStack {
                                    Text("Datum").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                    Spacer()
                                    Text(entry.date.shortFormatted).font(.apexBody).foregroundStyle(.apexTextPrimary)
                                }
                                Divider().background(.white.opacity(0.1))
                                HStack {
                                    Text("Gewicht").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                    Spacer()
                                    Text(String(format: "%.1f kg", entry.weightKg)).font(.apexHeadline).foregroundStyle(.apexCyan)
                                }
                                if let bf = entry.bodyFatPercent {
                                    Divider().background(.white.opacity(0.1))
                                    HStack {
                                        Text("Körperfett").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                        Spacer()
                                        Text(String(format: "%.1f%%", bf)).font(.apexHeadline).foregroundStyle(.apexCyan)
                                    }
                                }
                            }
                        }
                        .apexPadding()

                        // AI Analysis
                        if entry.photoFront != nil {
                            aiAnalysisCard
                                .apexPadding()
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Körperanalyse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { dismiss() }.foregroundStyle(.apexCyan)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        switch fotoTyp {
                        case .front: entry.photoFront = data
                        case .side:  entry.photoSide  = data
                        case .back:  entry.photoBack  = data
                        }
                        try? context.save()
                    }
                }
            }
        }
    }

    private var aiAnalysisCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "brain.head.profile").foregroundStyle(.apexCyan)
                    Text("KI-Körperanalyse").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                    Spacer()
                    Text("KI-Schätzung")
                        .font(.system(size: 9, weight: .bold)).foregroundStyle(.black)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Capsule().fill(Color.apexYellow))
                }

                if let analysis = entry.aiAnalysis {
                    Text(analysis)
                        .font(.apexBody).foregroundStyle(.apexTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("⚠️ Dies ist eine KI-Schätzung, keine medizinische Diagnose. Bei Beschwerden oder Schmerzen bitte einen Arzt oder Physiotherapeuten aufsuchen.")
                        .font(.apexCaption).foregroundStyle(.apexTextTertiary)
                } else {
                    Text("Lass die KI dein Frontfoto analysieren und Feedback zu Haltung, Symmetrie und Muskelentwicklung erhalten.")
                        .font(.apexCallout).foregroundStyle(.apexTextSecondary)
                }

                APEXButton(
                    title: isAnalyzing ? "Analysiere…" : (entry.aiAnalysis == nil ? "Jetzt analysieren" : "Neu analysieren"),
                    icon: "sparkles",
                    style: .secondary,
                    isEnabled: !isAnalyzing
                ) {
                    analyzeBody()
                }
            }
        }
    }

    private func analyzeBody() {
        guard let data = entry.photoFront, let img = UIImage(data: data) else { return }
        isAnalyzing = true
        Task {
            do {
                let analysis = try await ai.analyzeBody(frontPhoto: img)
                entry.aiAnalysis = analysis
                try? context.save()
            } catch {}
            await MainActor.run { isAnalyzing = false }
        }
    }
}

// MARK: - Vergleich View
struct VergleichView: View {
    var entry1: BodyEntry
    var entry2: BodyEntry
    var allEntries: [BodyEntry]
    var onChangeEntry1: (BodyEntry) -> Void
    var onChangeEntry2: (BodyEntry) -> Void

    var body: some View {
        GlassCard {
            VStack(spacing: Spacing.md) {
                Text("Vorher / Nachher")
                    .font(.apexHeadline).foregroundStyle(.apexTextPrimary)

                HStack(spacing: Spacing.md) {
                    fotoColumn(entry: entry1, label: "Vorher", onChange: onChangeEntry1)
                    fotoColumn(entry: entry2, label: "Nachher", onChange: onChangeEntry2)
                }

                // Weight diff
                let diff = entry2.weightKg - entry1.weightKg
                HStack {
                    Text("Unterschied:").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                    Spacer()
                    Text(String(format: "%+.1f kg", diff))
                        .font(.apexHeadline)
                        .foregroundStyle(diff <= 0 ? .apexGreen : .apexRed)
                }
            }
        }
    }

    private func fotoColumn(entry: BodyEntry, label: String, onChange: @escaping (BodyEntry) -> Void) -> some View {
        VStack(spacing: Spacing.sm) {
            Text(label).font(.apexCaption).foregroundStyle(.apexTextTertiary)

            ZStack {
                RoundedRectangle(cornerRadius: Radius.md).fill(Color.apexSurface).frame(height: 140)
                if let data = entry.photoFront, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(height: 140).clipShape(RoundedRectangle(cornerRadius: Radius.md))
                } else {
                    Image(systemName: "person.fill").font(.title).foregroundStyle(.apexTextTertiary)
                }
            }

            Text(entry.date.shortFormatted).font(.apexCaption).foregroundStyle(.apexTextSecondary)
            Text(String(format: "%.1f kg", entry.weightKg)).font(.apexCallout).foregroundStyle(.apexTextPrimary)

            Menu {
                ForEach(allEntries) { e in
                    Button(action: { onChange(e) }) {
                        Text("\(e.date.shortFormatted) – \(String(format: "%.1f kg", e.weightKg))")
                    }
                }
            } label: {
                Text("Ändern").font(.apexCaption).foregroundStyle(.apexCyan)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Foto Eintrag Editor
struct FotoEintragEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var weightKg     = 75.0
    @State private var bodyFat      = ""
    @State private var date         = Date()
    @State private var notes        = ""
    @State private var frontItem: PhotosPickerItem?
    @State private var sideItem:  PhotosPickerItem?
    @State private var backItem:  PhotosPickerItem?
    @State private var frontData: Data?
    @State private var sideData:  Data?
    @State private var backData:  Data?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        GlassCard {
                            VStack(spacing: Spacing.md) {
                                DatePicker("Datum", selection: $date, displayedComponents: .date).colorScheme(.dark)
                                Divider().background(.white.opacity(0.1))
                                HStack {
                                    Text("Gewicht").font(.apexBody).foregroundStyle(.apexTextSecondary)
                                    Spacer()
                                    Text(String(format: "%.1f kg", weightKg)).font(.apexCallout).foregroundStyle(.apexCyan)
                                }
                                Slider(value: $weightKg, in: 40...200, step: 0.1).tint(.apexCyan)
                                Divider().background(.white.opacity(0.1))
                                HStack {
                                    Text("Körperfett % (opt.)").font(.apexBody).foregroundStyle(.apexTextSecondary)
                                    Spacer()
                                    TextField("z.B. 14", text: $bodyFat)
                                        .font(.apexBody).foregroundStyle(.apexTextPrimary)
                                        .multilineTextAlignment(.trailing).keyboardType(.decimalPad).frame(width: 60)
                                }
                            }
                        }

                        // Fotos
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Fotos (optional)").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                                HStack(spacing: Spacing.md) {
                                    fotoPickerZelle(label: "Vorne", data: frontData, item: $frontItem, onLoad: { frontData = $0 })
                                    fotoPickerZelle(label: "Seite", data: sideData, item: $sideItem, onLoad: { sideData = $0 })
                                    fotoPickerZelle(label: "Rücken", data: backData, item: $backItem, onLoad: { backData = $0 })
                                }
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
            .navigationTitle("Eintrag erstellen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }.foregroundStyle(.apexTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let entry = BodyEntry(date: date, weightKg: weightKg, bodyFatPercent: Double(bodyFat), notes: notes)
                        entry.photoFront = frontData
                        entry.photoSide  = sideData
                        entry.photoBack  = backData
                        context.insert(entry)
                        try? context.save()
                        dismiss()
                    }
                    .foregroundStyle(.apexCyan)
                }
            }
        }
    }

    @ViewBuilder
    private func fotoPickerZelle(label: String, data: Data?, item: Binding<PhotosPickerItem?>, onLoad: @escaping (Data) -> Void) -> some View {
        PhotosPicker(selection: item, matching: .images) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md).fill(Color.apexSurface).frame(height: 80)
                    if let d = data, let img = UIImage(data: d) {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(height: 80).clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    } else {
                        Image(systemName: "plus").font(.title2).foregroundStyle(.apexCyan)
                    }
                }
                Text(label).font(.apexCaption).foregroundStyle(.apexTextSecondary)
            }
        }
        .onChange(of: item.wrappedValue) { _, new in
            Task {
                if let d = try? await new?.loadTransferable(type: Data.self) {
                    await MainActor.run { onLoad(d) }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
