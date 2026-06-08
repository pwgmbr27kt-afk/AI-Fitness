import SwiftUI
import SwiftData
import PhotosUI

struct AICoachView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChatMessage.timestamp) private var messages: [ChatMessage]
    @Query private var profiles: [UserProfile]
    @Query(sort: \DayNutrition.date, order: .reverse) private var nutritionDays: [DayNutrition]
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.date, order: .reverse
    ) private var recentSessions: [WorkoutSession]

    @StateObject private var ai = AIService.shared
    @State private var inputText  = ""
    @State private var isLoading  = false
    @State private var showApiHint = false
    @State private var photoItem: PhotosPickerItem?
    @State private var attachedImage: UIImage?
    @FocusState private var inputFocused: Bool

    private var profile: UserProfile? { profiles.first }
    private var todayNutrition: DayNutrition? { nutritionDays.first { Calendar.current.isDateInToday($0.date) } }

    private let schnellPrompts = [
        "Was soll ich heute essen?",
        "Analysiere mein heutiges Training",
        "Wie optimiere ich meine Regeneration?",
        "Erstelle mir einen Ernährungsplan",
        "Welche Supplements empfiehlst du?",
        "Tipps für mehr Muskelmasse",
        "Wie verbessere ich meinen Schlaf?",
        "Leg-Day Übungen ohne Geräte"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Context banner
                    if let p = profile {
                        kontextBanner(p)
                    }

                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: Spacing.sm) {
                                if messages.isEmpty {
                                    leeresState
                                } else {
                                    ForEach(messages) { msg in
                                        NachrichtBubble(message: msg)
                                            .id(msg.id)
                                    }
                                    if isLoading {
                                        tippIndikator.id("typing")
                                    }
                                }
                            }
                            .padding(.vertical, Spacing.md)
                            .padding(.bottom, 20)
                        }
                        .onChange(of: messages.count) { _, _ in
                            withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
                        }
                        .onChange(of: isLoading) { _, l in
                            if l { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
                        }
                    }

                    // Attached image preview
                    if let img = attachedImage {
                        HStack {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Foto angehängt").font(.apexCallout).foregroundStyle(.apexTextPrimary)
                                Text("Wird mit Nachricht gesendet").font(.apexCaption).foregroundStyle(.apexTextTertiary)
                            }
                            Spacer()
                            Button { attachedImage = nil } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.apexTextSecondary)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(.ultraThinMaterial)
                    }

                    eingabeLeiste
                }
            }
            .navigationTitle("KI-Coach")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Chat leeren", role: .destructive) { chatLeeren() }
                        Button("API-Key prüfen") { showApiHint = true }
                    } label: {
                        Image(systemName: "ellipsis.circle").foregroundStyle(.apexTextSecondary)
                    }
                }
            }
            .alert("API-Key", isPresented: $showApiHint) {
                Button("OK", role: .cancel) {}
            } message: {
                let hasKey = KeychainService.shared.get(account: AppConfiguration.keychainAPIKeyAccount) != nil
                Text(hasKey ? "API-Key ist gespeichert ✓" : "Kein API-Key gefunden. Bitte in Einstellungen → KI Coach eingeben.")
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        await MainActor.run { attachedImage = UIImage(data: data) }
                    }
                }
            }
        }
    }

    // MARK: - Kontext Banner
    private func kontextBanner(_ p: UserProfile) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                kontextChip(icon: "target", text: p.goalType.displayName)
                kontextChip(icon: "flame.fill", text: "\(p.calorieGoal) kcal Ziel")
                if let n = todayNutrition {
                    kontextChip(icon: "fork.knife", text: "\(n.totalCalories) kcal heute")
                }
                if let last = recentSessions.first {
                    kontextChip(icon: "dumbbell.fill", text: last.name)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }

    private func kontextChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9)).foregroundStyle(.apexCyan)
            Text(text).font(.system(size: 10)).foregroundStyle(.apexTextSecondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(Color.white.opacity(0.06)))
    }

    // MARK: - Leeres State
    private var leeresState: some View {
        VStack(spacing: Spacing.xl) {
            Spacer().frame(height: 40)

            ZStack {
                Circle().fill(Color.apexAccentGradient).frame(width: 90, height: 90).glowEffect()
                Image(systemName: "brain.head.profile").font(.system(size: 44)).foregroundStyle(.black)
            }
            .bounceIn()

            VStack(spacing: Spacing.sm) {
                Text("APEX Coach")
                    .font(.apexTitle).foregroundStyle(.apexTextPrimary)
                Text("Dein KI-Fitness-Assistent.\nFrag mich alles über Training, Ernährung und Lifestyle.")
                    .font(.apexBody).foregroundStyle(.apexTextSecondary).multilineTextAlignment(.center)
            }
            .slideUp(delay: 0.1)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Vorschläge").font(.apexCaption).foregroundStyle(.apexTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(schnellPrompts.prefix(4), id: \.self) { prompt in
                    Button {
                        inputText = prompt
                        nachrichtSenden()
                    } label: {
                        HStack {
                            Text(prompt).font(.apexBody).foregroundStyle(.apexTextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "arrow.up.circle").foregroundStyle(.apexCyan)
                        }
                        .padding(Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.lg).fill(.ultraThinMaterial)
                                .overlay { RoundedRectangle(cornerRadius: Radius.lg).stroke(Color.white.opacity(0.08), lineWidth: 1) }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .slideUp(delay: 0.2)
        }
    }

    // MARK: - Tipp Indikator
    private var tippIndikator: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            ZStack {
                Circle().fill(Color.apexAccentGradient).frame(width: 30, height: 30)
                Text("A").font(.system(size: 12, weight: .bold)).foregroundStyle(.black)
            }
            GlassCard(padding: Spacing.md) {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in TippPunkt(delay: Double(i) * 0.2) }
                }
            }
            Spacer(minLength: 60)
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Eingabe Leiste
    private var eingabeLeiste: some View {
        HStack(spacing: Spacing.sm) {
            // Photo attachment
            PhotosPicker(selection: $photoItem, matching: .images) {
                Image(systemName: attachedImage != nil ? "photo.fill" : "photo")
                    .font(.title3)
                    .foregroundStyle(attachedImage != nil ? .apexCyan : .apexTextTertiary)
            }

            // Text input
            TextField("Nachricht schreiben…", text: $inputText, axis: .vertical)
                .font(.apexBody)
                .foregroundStyle(.apexTextPrimary)
                .lineLimit(1...5)
                .focused($inputFocused)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: Radius.pill)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: Radius.pill)
                                .stroke(inputFocused ? Color.apexCyan.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                        }
                }

            // Send button
            Button { nachrichtSenden() } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle((inputText.isNotEmpty || attachedImage != nil) && !isLoading ? .apexCyan : .apexTextTertiary)
            }
            .disabled((inputText.isEmpty && attachedImage == nil) || isLoading)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions
    private func nachrichtSenden() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isNotEmpty || attachedImage != nil else { return }

        let image = attachedImage
        let userMsg = ChatMessage(role: "user", content: text.isEmpty ? "[Foto gesendet]" : text)
        context.insert(userMsg)
        inputText = ""
        attachedImage = nil
        photoItem = nil
        isLoading = true
        inputFocused = false

        Task {
            do {
                let response: String
                if let img = image {
                    // Send image + text
                    guard let jpeg = img.jpegData(compressionQuality: 0.7) else { throw AIServiceError.invalidResponse }
                    let b64 = jpeg.base64EncodedString()
                    var content: [AnthropicContent] = [.image(base64: b64)]
                    if text.isNotEmpty { content.append(.text(text)) }
                    else { content.append(.text("Analysiere dieses Bild im Kontext meines Fitness-Programms.")) }
                    let msgs = [AnthropicMessage(role: "user", content: content)]
                    response = try await ai.send(systemPrompt: buildSystemPrompt(), messages: msgs, maxTokens: 1024)
                } else {
                    response = try await ai.chat(profile: profile ?? UserProfile(), history: messages, userMessage: text)
                }
                let assistantMsg = ChatMessage(role: "assistant", content: response)
                context.insert(assistantMsg)
            } catch {
                let errMsg = ChatMessage(role: "assistant", content: "Fehler: \(error.localizedDescription)", isError: true)
                context.insert(errMsg)
            }
            await MainActor.run {
                isLoading = false
                try? context.save()
            }
        }
    }

    private func chatLeeren() {
        messages.forEach { context.delete($0) }
        try? context.save()
    }

    private func buildSystemPrompt() -> String {
        var prompt = """
        Du bist APEX Coach, ein persönlicher KI-Fitness- und Lifestyle-Assistent.
        Antworte auf Deutsch, klar und motivierend.
        """
        if let p = profile {
            prompt += """
            \nNutzerprofil: \(p.name), \(p.age) Jahre, \(Int(p.heightCm)) cm, \(String(format: "%.1f", p.weightKg)) kg
            Ziel: \(p.goalType.displayName), Aktivität: \(p.activityLevel.displayName)
            Kalorienziel: \(p.calorieGoal) kcal, Protein: \(p.proteinGoal)g
            """
        }
        if let n = todayNutrition {
            prompt += "\nHeute gegessen: \(n.totalCalories) kcal, \(Int(n.totalProtein))g Protein"
        }
        if let last = recentSessions.first {
            prompt += "\nLetztes Workout: \(last.name)"
        }
        prompt += "\n\nRegeln: Keine medizinischen Diagnosen. Bei Schmerzen immer Arzt empfehlen. KI-Schätzungen als solche kennzeichnen."
        return prompt
    }
}

// MARK: - Nachricht Bubble
struct NachrichtBubble: View {
    var message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            if message.isUser { Spacer(minLength: 50) }

            if !message.isUser {
                ZStack {
                    Circle().fill(Color.apexAccentGradient).frame(width: 28, height: 28)
                    Text("A").font(.system(size: 11, weight: .bold)).foregroundStyle(.black)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if message.isError {
                    Text(message.content)
                        .font(.apexCallout).foregroundStyle(.apexRed)
                        .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm)
                        .background { RoundedRectangle(cornerRadius: Radius.lg).fill(Color.apexRed.opacity(0.15)) }
                } else {
                    Text(message.content)
                        .font(.apexBody)
                        .foregroundStyle(message.isUser ? .black : .apexTextPrimary)
                        .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm)
                        .background {
                            if message.isUser {
                                RoundedRectangle(cornerRadius: Radius.lg).fill(Color.apexAccentGradient)
                            } else {
                                RoundedRectangle(cornerRadius: Radius.lg).fill(.ultraThinMaterial)
                                    .overlay { RoundedRectangle(cornerRadius: Radius.lg).stroke(Color.white.opacity(0.08), lineWidth: 1) }
                            }
                        }
                }
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.apexCaption).foregroundStyle(.apexTextTertiary)
            }

            if !message.isUser { Spacer(minLength: 50) }
        }
        .padding(.horizontal, Spacing.md)
    }
}

struct TippPunkt: View {
    var delay: Double
    @State private var scale: CGFloat = 0.4

    var body: some View {
        Circle().fill(Color.apexTextSecondary).frame(width: 7, height: 7)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(delay)) {
                    scale = 1.0
                }
            }
    }
}
