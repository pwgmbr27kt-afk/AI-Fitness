import SwiftUI

struct ExerciseRow: View {
    var exercise: Exercise
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: Spacing.md) {
                // Muscle group icon
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(Color.apexCyan.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: exercise.muscleGroup.icon)
                        .font(.callout)
                        .foregroundStyle(.apexCyan)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(.apexBody)
                        .foregroundStyle(.apexTextPrimary)
                    Text("\(exercise.totalSetsCount) Sätze · \(exercise.muscleGroup.displayName)")
                        .font(.apexCaption)
                        .foregroundStyle(.apexTextSecondary)
                }

                Spacer()

                // Completion badge
                if exercise.totalSetsCount > 0 {
                    Text("\(exercise.completedSetsCount)/\(exercise.totalSetsCount)")
                        .font(.apexCallout)
                        .foregroundStyle(exercise.completedSetsCount == exercise.totalSetsCount ? .apexGreen : .apexTextSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.apexTextTertiary)
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}
