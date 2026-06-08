import SwiftUI
import SwiftData

struct AICoachView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChatMessage.timestamp) private var messages: [ChatMessage]
    @Query private var profiles: [UserProfile]

    @StateObject private var ai = AIService.shared
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var inputFocused: Bool

    private var profile: UserProfile? { profiles.first }

    private let suggestedPrompts = [
        "Was soll ich heute essen?",
        "Tipps für mehr Muskelmasse",
        "Wie optimiere ich meinen Schlaf?",
        "Leg-Day Übungen für zuhause",
        "Wie berechne ich meinen TDEE?"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: Spacing.sm) {
                                if messages.isEmpty {
                                    emptyState
                                } else {
                                    ForEach(messages) { msg in
                                        AIMessageBubble(message: msg)
                                            .id(msg.id)
                                    }
                                    if isLoading {
                                        typingIndicator
                                    }
                                }
                            }
                            .padding(.vertical, Spacing.md)
                        }
                        .onChange(of: messages.count) { _, _ in
                            withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
                        }
                        .onChange(of: isLoading) { _, loading in
                            if loading {
                                withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                            }
                        }
                    }

                    // Input bar
                    inputBar
                }
            }
            .navigationTitle("APEX Coach")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        clearChat()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.apexTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: Spacing.xl) {
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(Color.apexAccentGradient)
                    .frame(width: 80, height: 80)
                    .glowEffect()
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36))
                    .foregroundStyle(.black)
            }

            VStack(spacing: Spacing.sm) {
                Text("APEX Coach")
                    .font(.apexTitle)
                    .foregroundStyle(.apexTextPrimary)
                Text("Dein persönlicher KI-Fitness-Assistent.\nFrag mich alles rund um Training, Ernährung und Lifestyle.")
                    .font(.apexBody)
                    .foregroundStyle(.apexTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Suggested prompts
            VStack(spacing: Spacing.sm) {
                Text("Vorschläge").font(.apexCallout).foregroundStyle(.apexTextTertiary)
                ForEach(suggestedPrompts, id: \.self) { prompt in
                    Button {
                        inputText = prompt
                        sendMessage()
                    } label: {
                        Text(prompt)
                            .font(.apexBody)
                            .foregroundStyle(.apexTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Spacing.md)
                            .background {
                                RoundedRectangle(cornerRadius: Radius.lg)
                                    .fill(.ultraThinMaterial)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: Radius.lg)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Typing Indicator
    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            ZStack {
                Circle().fill(Color.apexAccentGradient).frame(width: 30, height: 30)
                Text("A").font(.system(size: 12, weight: .bold)).foregroundStyle(.black)
            }
            GlassCard(padding: Spacing.md) {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        TypingDot(delay: Double(i) * 0.2)
                    }
                }
            }
            Spacer(minLength: 60)
        }
        .padding(.horizontal, Spacing.md)
        .id("typing")
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Nachricht eingeben…", text: $inputText, axis: .vertical)
                .font(.apexBody)
                .foregroundStyle(.apexTextPrimary)
                .lineLimit(1...4)
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

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(inputText.isNotEmpty && !isLoading ? .apexCyan : .apexTextTertiary)
            }
            .disabled(inputText.isEmpty || isLoading)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isNotEmpty else { return }

        let userMsg = ChatMessage(role: "user", content: text)
        context.insert(userMsg)
        inputText = ""
        isLoading = true
        inputFocused = false

        Task {
            do {
                let response = try await ai.chat(
                    profile: profile ?? UserProfile(),
                    history: messages,
                    userMessage: text
                )
                let assistantMsg = ChatMessage(role: "assistant", content: response)
                context.insert(assistantMsg)
            } catch {
                let errMsg = ChatMessage(role: "assistant", content: "Fehler: \(error.localizedDescription)", isError: true)
                context.insert(errMsg)
            }
            isLoading = false
            try? context.save()
        }
    }

    private func clearChat() {
        messages.forEach { context.delete($0) }
        try? context.save()
    }
}

struct TypingDot: View {
    var delay: Double
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Circle()
            .fill(Color.apexTextSecondary)
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever().delay(delay)) {
                    scale = 1.0
                }
            }
    }
}
