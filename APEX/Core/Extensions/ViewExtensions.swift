import SwiftUI

extension View {
    // Apply conditional modifier
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, apply transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }

    // Haptic feedback
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        onTapGesture {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }

    // Standard section padding
    func apexPadding() -> some View {
        padding(.horizontal, Spacing.md)
    }

    // Navigation bar styling
    func apexNavigationBar(title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
}

extension String {
    var isNotEmpty: Bool { !isEmpty }
}

extension Double {
    func formatted(decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f", self)
    }
}

extension Int {
    var durationFormatted: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
