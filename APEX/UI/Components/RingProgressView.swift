import SwiftUI

struct RingProgressView: View {
    var progress: Double          // 0.0 – 1.0
    var lineWidth: CGFloat = 10
    var size: CGFloat = 80
    var color: Color = .apexCyan
    var trackColor: Color = Color.white.opacity(0.08)
    var label: String? = nil
    var sublabel: String? = nil
    var showPercent: Bool = false

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            // Fill
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 2) {
                if let label {
                    Text(label)
                        .font(.apexNumber)
                        .foregroundStyle(color)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                if showPercent {
                    Text("\(Int(animatedProgress * 100))%")
                        .font(.apexCallout)
                        .foregroundStyle(.apexTextSecondary)
                }
                if let sublabel {
                    Text(sublabel)
                        .font(.apexCaption)
                        .foregroundStyle(.apexTextTertiary)
                        .lineLimit(1)
                }
            }
            .frame(width: size * 0.65)
        }
        .frame(width: size, height: size)
        .onAppear { animate() }
        .onChange(of: progress) { animate() }
    }

    private func animate() {
        withAnimation(.easeInOut(duration: 0.8)) {
            animatedProgress = min(1.0, max(0, progress))
        }
    }
}

// MARK: - Compact ring (no center label, just fill)
struct SmallRingView: View {
    var progress: Double
    var color: Color = .apexCyan
    var size: CGFloat = 40
    var lineWidth: CGFloat = 5

    @State private var animated: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animated)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) { animated = min(1, max(0, progress)) }
        }
        .onChange(of: progress) { _, new in
            withAnimation(.easeInOut(duration: 0.5)) { animated = min(1, max(0, new)) }
        }
    }
}

#Preview {
    ZStack {
        Color.apexBackground.ignoresSafeArea()
        HStack(spacing: 24) {
            RingProgressView(progress: 0.72, label: "1800", sublabel: "kcal")
            RingProgressView(progress: 0.55, color: .apexPurple, label: "142g", sublabel: "Protein")
            RingProgressView(progress: 0.30, color: .apexBlue, label: "0.9L", sublabel: "Wasser")
        }
    }
}
