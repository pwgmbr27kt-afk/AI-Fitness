import SwiftUI

struct AIMessageBubble: View {
    var message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            if message.isUser { Spacer(minLength: 60) }

            if !message.isUser {
                // AI avatar
                ZStack {
                    Circle()
                        .fill(Color.apexAccentGradient)
                        .frame(width: 30, height: 30)
                    Text("A")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.apexBody)
                    .foregroundStyle(message.isUser ? .black : .apexTextPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background {
                        if message.isUser {
                            RoundedRectangle(cornerRadius: Radius.lg)
                                .fill(Color.apexAccentGradient)
                        } else {
                            RoundedRectangle(cornerRadius: Radius.lg)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: Radius.lg)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                }
                        }
                    }
                    .overlay(alignment: message.isUser ? .bottomTrailing : .bottomLeading) {
                        if message.isAIEstimate {
                            Text("KI-Schätzung")
                                .font(.apexCaption)
                                .foregroundStyle(.apexTextTertiary)
                                .padding(.bottom, -16)
                        }
                    }

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.apexCaption)
                    .foregroundStyle(.apexTextTertiary)
            }

            if !message.isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, Spacing.md)
    }
}

extension ChatMessage {
    var isAIEstimate: Bool { !isUser && content.contains("KI-Schätzung") }
}
