import SwiftUI

// MARK: - Bounce on appear
struct BounceModifier: ViewModifier {
    @State private var appeared = false
    var delay: Double = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Slide up on appear
struct SlideUpModifier: ViewModifier {
    @State private var appeared = false
    var delay: Double = 0
    var distance: CGFloat = 30

    func body(content: Content) -> some View {
        content
            .offset(y: appeared ? 0 : distance)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Pulse glow
struct PulseModifier: ViewModifier {
    @State private var pulsing = false
    var color: Color = .apexCyan

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(pulsing ? 0.6 : 0.15), radius: pulsing ? 12 : 4)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
    }
}

// MARK: - Shimmer loading
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: phase - 0.3),
                        .init(color: .white.opacity(0.06), location: phase),
                        .init(color: .clear, location: phase + 0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1.5
                    }
                }
            }
    }
}

extension View {
    func bounceIn(delay: Double = 0) -> some View {
        modifier(BounceModifier(delay: delay))
    }

    func slideUp(delay: Double = 0, distance: CGFloat = 30) -> some View {
        modifier(SlideUpModifier(delay: delay, distance: distance))
    }

    func pulseGlow(color: Color = .apexCyan) -> some View {
        modifier(PulseModifier(color: color))
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
