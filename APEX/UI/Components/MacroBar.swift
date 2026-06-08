import SwiftUI

struct MacroBar: View {
    var label: String
    var current: Double
    var goal: Double
    var unit: String
    var color: Color = .apexCyan

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, current / goal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.apexCallout)
                    .foregroundStyle(.apexTextSecondary)
                Spacer()
                Text("\(Int(current))/\(Int(goal))\(unit)")
                    .font(.apexCallout)
                    .foregroundStyle(.apexTextPrimary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)

                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.easeInOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}
