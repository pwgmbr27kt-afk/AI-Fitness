import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query(sort: \DaySection.sortOrder) private var sections: [DaySection]
    @StateObject private var healthKit   = HealthKitService.shared
    @StateObject private var cloudSync   = CloudSyncService.shared

    @State private var apiKey = ""
    @State private var showAPIKeyField = false
    @State private var showDeleteDataAlert = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                List {
                    // Profile
                    Section {
                        NavigationLink(destination: ProfileEditorView(profile: profile)) {
                            profileRow
                        }
                        .listRowBackground(Color.apexCard)
                    } header: { sectionHeader("Profil") }

                    // Goals
                    if let p = profile {
                        Section {
                            NavigationLink(destination: GoalsEditorView(profile: p)) {
                                settingsRow(icon: "target", label: "Ziele & Makros", value: "\(p.calorieGoal) kcal")
                            }
                        } header: { sectionHeader("Ziele") }
                        .listRowBackground(Color.apexCard)
                    }

                    // Day Sections
                    Section {
                        NavigationLink(destination: SectionsManagementView()) {
                            settingsRow(icon: "list.bullet.rectangle", label: "Tagesbereiche", value: "\(sections.count) Bereiche")
                        }
                    } header: { sectionHeader("Planer") }
                    .listRowBackground(Color.apexCard)

                    // AI
                    Section {
                        Button {
                            showAPIKeyField.toggle()
                            if !showAPIKeyField { }
                            else { apiKey = KeychainService.shared.get(account: AppConfiguration.keychainAPIKeyAccount) ?? "" }
                        } label: {
                            settingsRow(icon: "key.fill", label: "Anthropic API Key",
                                        value: KeychainService.shared.get(account: AppConfiguration.keychainAPIKeyAccount).map { _ in "✓ Gespeichert" } ?? "Nicht gesetzt")
                        }
                        .listRowBackground(Color.apexCard)

                        if showAPIKeyField {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                SecureField("sk-ant-...", text: $apiKey)
                                    .font(.apexBody).foregroundStyle(.apexTextPrimary)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                APEXButton(title: "Speichern") {
                                    KeychainService.shared.save(apiKey, account: AppConfiguration.keychainAPIKeyAccount)
                                    showAPIKeyField = false
                                }
                            }
                            .listRowBackground(Color.apexCard)
                        }
                    } header: { sectionHeader("KI Coach") }

                    // Health
                    Section {
                        Button {
                            Task { try? await healthKit.requestPermission() }
                        } label: {
                            settingsRow(
                                icon: "heart.fill",
                                label: "Apple Health",
                                value: healthKit.isAuthorized ? "Verbunden" : "Verbinden",
                                valueColor: healthKit.isAuthorized ? .apexGreen : .apexCyan
                            )
                        }
                        .listRowBackground(Color.apexCard)
                    } header: { sectionHeader("Integrationen") }

                    // iCloud
                    Section {
                        settingsRow(
                            icon: "icloud.fill",
                            label: "iCloud Sync",
                            value: cloudSync.syncStatus.rawValue,
                            valueColor: cloudSync.iCloudAvailable ? .apexGreen : .apexTextTertiary
                        )
                        .listRowBackground(Color.apexCard)
                    } header: { sectionHeader("Synchronisierung") }

                    // Data
                    Section {
                        Button(role: .destructive) {
                            showDeleteDataAlert = true
                        } label: {
                            settingsRow(icon: "trash.fill", label: "Alle Daten löschen", valueColor: .apexRed)
                        }
                        .listRowBackground(Color.apexCard)
                    } header: { sectionHeader("Daten") }

                    // About
                    Section {
                        settingsRow(icon: "info.circle.fill", label: "Version", value: "\(AppConfiguration.appVersion) (\(AppConfiguration.buildNumber))")
                            .listRowBackground(Color.apexCard)
                    } header: { sectionHeader("Über APEX") }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Einstellungen")
            .alert("Alle Daten löschen?", isPresented: $showDeleteDataAlert) {
                Button("Löschen", role: .destructive) { deleteAllData() }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
    }

    private var profileRow: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle().fill(Color.apexAccentGradient).frame(width: 44, height: 44)
                Text(String(profile?.name.prefix(1).uppercased() ?? "A"))
                    .font(.apexHeadline).foregroundStyle(.black)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(profile?.name ?? "Profil").font(.apexHeadline).foregroundStyle(.apexTextPrimary)
                if let p = profile {
                    Text("\(p.age) Jahre · \(Int(p.heightCm)) cm · \(String(format: "%.1f", p.weightKg)) kg")
                        .font(.apexCaption).foregroundStyle(.apexTextSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func settingsRow(icon: String, label: String, value: String? = nil, valueColor: Color = .apexTextSecondary) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(.apexCyan)
                .frame(width: 24)
            Text(label).font(.apexBody).foregroundStyle(.apexTextPrimary)
            Spacer()
            if let v = value {
                Text(v).font(.apexCallout).foregroundStyle(valueColor)
            }
        }
        .padding(.vertical, 4)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(.apexCaption).foregroundStyle(.apexTextTertiary).textCase(nil)
    }

    private func deleteAllData() {
        // Delete all model types
        (try? context.fetch(FetchDescriptor<APEXTask>()))?.forEach { context.delete($0) }
        (try? context.fetch(FetchDescriptor<DaySection>()))?.forEach { context.delete($0) }
        (try? context.fetch(FetchDescriptor<WorkoutSession>()))?.forEach { context.delete($0) }
        (try? context.fetch(FetchDescriptor<WorkoutPlan>()))?.forEach { context.delete($0) }
        (try? context.fetch(FetchDescriptor<DayNutrition>()))?.forEach { context.delete($0) }
        (try? context.fetch(FetchDescriptor<BodyEntry>()))?.forEach { context.delete($0) }
        (try? context.fetch(FetchDescriptor<Reminder>()))?.forEach { context.delete($0) }
        (try? context.fetch(FetchDescriptor<MobilityRoutine>()))?.forEach { context.delete($0) }
        (try? context.fetch(FetchDescriptor<ChatMessage>()))?.forEach { context.delete($0) }
        (try? context.fetch(FetchDescriptor<UserProfile>()))?.forEach { context.delete($0) }
        try? context.save()
    }
}

// MARK: - Profile Editor
struct ProfileEditorView: View {
    var profile: UserProfile?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var birthDate = Date()
    @State private var heightCm = 175.0
    @State private var weightKg = 75.0
    @State private var goalType: GoalType = .maintain
    @State private var activityLevel: ActivityLevel = .moderate

    var body: some View {
        ZStack {
            Color.apexBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Spacing.md) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Name").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                            TextField("Name", text: $name).font(.apexBody).foregroundStyle(.apexTextPrimary)
                        }
                    }
                    GlassCard {
                        VStack(spacing: Spacing.md) {
                            DatePicker("Geburtsdatum", selection: $birthDate, in: ...Date(), displayedComponents: .date).colorScheme(.dark)
                            Divider().background(.white.opacity(0.1))
                            HStack {
                                Text("Größe").font(.apexBody).foregroundStyle(.apexTextSecondary)
                                Spacer()
                                Text("\(Int(heightCm)) cm").font(.apexCallout).foregroundStyle(.apexTextPrimary)
                            }
                            Slider(value: $heightCm, in: 140...220, step: 1).tint(.apexCyan)
                            HStack {
                                Text("Gewicht").font(.apexBody).foregroundStyle(.apexTextSecondary)
                                Spacer()
                                Text(String(format: "%.1f kg", weightKg)).font(.apexCallout).foregroundStyle(.apexTextPrimary)
                            }
                            Slider(value: $weightKg, in: 40...200, step: 0.5).tint(.apexBlue)
                        }
                    }
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Ziel").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                            Picker("", selection: $goalType) {
                                ForEach(GoalType.allCases, id: \.self) { Text($0.displayName).tag($0) }
                            }
                            .pickerStyle(.menu).tint(.apexCyan)
                        }
                    }
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Aktivitätslevel").font(.apexCallout).foregroundStyle(.apexTextSecondary)
                            Picker("", selection: $activityLevel) {
                                ForEach(ActivityLevel.allCases, id: \.self) { Text($0.displayName).tag($0) }
                            }
                            .pickerStyle(.menu).tint(.apexCyan)
                        }
                    }
                }
                .apexPadding().padding(.vertical, Spacing.md)
            }
        }
        .navigationTitle("Profil bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") { save() }.foregroundStyle(.apexCyan)
            }
        }
        .onAppear {
            guard let p = profile else { return }
            name          = p.name
            birthDate     = p.birthDate
            heightCm      = p.heightCm
            weightKg      = p.weightKg
            goalType      = p.goalType
            activityLevel = p.activityLevel
        }
    }

    private func save() {
        guard let p = profile else { return }
        p.name          = name
        p.birthDate     = birthDate
        p.heightCm      = heightCm
        p.weightKg      = weightKg
        p.goalType      = goalType
        p.activityLevel = activityLevel
        p.updatedAt     = Date()
        try? context.save()
        dismiss()
    }
}

// MARK: - Goals Editor
struct GoalsEditorView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.apexBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Spacing.md) {
                    GlassCard {
                        VStack(spacing: Spacing.md) {
                            goalStepper(label: "Kalorien (kcal)", value: $profile.calorieGoal, step: 50, range: 1000...5000)
                            Divider().background(.white.opacity(0.1))
                            goalStepper(label: "Protein (g)", value: $profile.proteinGoal, step: 5, range: 50...400)
                            Divider().background(.white.opacity(0.1))
                            goalStepper(label: "Kohlenhydrate (g)", value: $profile.carbGoal, step: 10, range: 0...600)
                            Divider().background(.white.opacity(0.1))
                            goalStepper(label: "Fett (g)", value: $profile.fatGoal, step: 5, range: 20...200)
                            Divider().background(.white.opacity(0.1))
                            goalStepper(label: "Wasser (ml)", value: $profile.waterGoalMl, step: 250, range: 1000...6000)
                        }
                    }

                    Button {
                        let goals = profile.suggestedGoals()
                        profile.calorieGoal = goals.calories
                        profile.proteinGoal = goals.protein
                        profile.carbGoal    = goals.carbs
                        profile.fatGoal     = goals.fat
                        profile.waterGoalMl = goals.water
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("TDEE neu berechnen")
                        }
                        .font(.apexBody).foregroundStyle(.apexCyan)
                        .frame(maxWidth: .infinity).padding(Spacing.md)
                        .background { RoundedRectangle(cornerRadius: Radius.lg).fill(Color.apexCyan.opacity(0.1)) }
                    }
                    .buttonStyle(.plain)
                }
                .apexPadding().padding(.vertical, Spacing.md)
            }
        }
        .navigationTitle("Ziele")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    try? context.save()
                    dismiss()
                }.foregroundStyle(.apexCyan)
            }
        }
    }

    private func goalStepper(label: String, value: Binding<Int>, step: Int, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label).font(.apexBody).foregroundStyle(.apexTextSecondary)
            Spacer()
            Stepper("\(value.wrappedValue)", value: value, in: range, step: step)
                .font(.apexCallout).foregroundStyle(.apexTextPrimary)
        }
    }
}

// MARK: - Sections Management
struct SectionsManagementView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DaySection.sortOrder) private var sections: [DaySection]
    @State private var showAddSection = false

    var body: some View {
        ZStack {
            Color.apexBackground.ignoresSafeArea()
            List {
                ForEach(sections) { section in
                    NavigationLink(destination: SectionEditorView(section: section)) {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: section.icon)
                                .foregroundStyle(Color(hex: section.colorHex))
                                .frame(width: 24)
                            Text(section.name).font(.apexBody).foregroundStyle(.apexTextPrimary)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.apexCard)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { context.delete(section) } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
                .onMove { from, to in
                    var sorted = sections
                    sorted.move(fromOffsets: from, toOffset: to)
                    for (i, s) in sorted.enumerated() { s.sortOrder = i }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Tagesbereiche")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddSection = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(.apexCyan)
                }
            }
            ToolbarItem(placement: .topBarLeading) { EditButton().foregroundStyle(.apexCyan) }
        }
        .sheet(isPresented: $showAddSection) { SectionEditorView() }
    }
}
