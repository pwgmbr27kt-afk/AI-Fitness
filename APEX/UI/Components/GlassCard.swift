import SwiftUI

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    var padding: CGFloat = Spacing.md
    var cornerRadius: CGFloat = Radius.lg
    var borderOpacity: Double = 0.12
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(borderOpacity), lineWidth: 1)
                    }
            }
    }
}

// MARK: - Accent Glass Card
struct AccentGlassCard<Content: View>: View {
    var accentColor: Color = .apexCyan
    var padding: CGFloat = Spacing.md
    var cornerRadius: CGFloat = Radius.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.5), accentColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .apexShadow(color: accentColor)
    }
}

// MARK: - Preview Helper
#Preview {
    ZStack {
        Color.apexBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            GlassCard {
                Text("Glass Card")
                    .foregroundStyle(.apexTextPrimary)
            }
            AccentGlassCard {
                Text("Accent Glass Card")
                    .foregroundStyle(.apexTextPrimary)
            }
        }
        .padding()
    }
}
