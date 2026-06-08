import SwiftUI

struct StatCard: View {
    var icon: String
    var value: String
    var label: String
    var trend: Double?       // positive = up, negative = down, nil = no trend
    var trendLabel: String?
    var accentColor: Color = .apexCyan

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(accentColor)
                    Spacer()
                    if let trend {
                        trendBadge(trend)
                    }
                }

                Text(value)
                    .font(.apexTitle)
                    .foregroundStyle(.apexTextPrimary)

                Text(label)
                    .font(.apexCallout)
                    .foregroundStyle(.apexTextSecondary)
            }
        }
    }

    @ViewBuilder
    private func trendBadge(_ trend: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
            if let trendLabel {
                Text(trendLabel)
                    .font(.apexCaption)
            }
        }
        .foregroundStyle(trend >= 0 ? .apexGreen : .apexRed)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule().fill((trend >= 0 ? Color.apexGreen : Color.apexRed).opacity(0.15))
        )
    }
}

#Preview {
    ZStack {
        Color.apexBackground.ignoresSafeArea()
        HStack {
            StatCard(icon: "flame.fill", value: "2180", label: "kcal heute", trend: 1.0, trendLabel: "+180", accentColor: .apexOrange)
            StatCard(icon: "dumbbell.fill", value: "5", label: "Workouts", trend: -1, trendLabel: "-1", accentColor: .apexCyan)
        }
        .padding()
    }
}
