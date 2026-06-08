import SwiftUI

struct TaskRow: View {
    @Bindable var task: APEXTask
    var onDelete: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Checkbox
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    task.isCompleted.toggle()
                    task.updatedAt = Date()
                    if task.isCompleted {
                        task.lastCompletedDate = Date()
                        task.streakCount += 1
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.apexCyan : Color.white.opacity(0.25), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if task.isCompleted {
                        Circle()
                            .fill(Color.apexCyan)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
            }
            .buttonStyle(.plain)

            // Category icon
            Image(systemName: task.category.icon)
                .font(.callout)
                .foregroundStyle(.apexTextSecondary)
                .frame(width: 20)

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.apexBody)
                    .foregroundStyle(task.isCompleted ? .apexTextTertiary : .apexTextPrimary)
                    .strikethrough(task.isCompleted, color: .apexTextTertiary)

                if let reminderTime = task.reminderTime {
                    Label(reminderTime.formatted(date: .omitted, time: .shortened), systemImage: "bell.fill")
                        .font(.apexCaption)
                        .foregroundStyle(.apexTextTertiary)
                }
            }

            Spacer()

            // Priority dot
            priorityDot
        }
        .padding(.vertical, Spacing.sm)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Löschen", systemImage: "trash")
                }
            }
            if let onEdit {
                Button(action: onEdit) {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                .tint(.apexBlue)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    task.isCompleted.toggle()
                    task.updatedAt = Date()
                }
            } label: {
                Label(task.isCompleted ? "Rückgängig" : "Erledigt", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
            }
            .tint(.apexCyan)
        }
    }

    @ViewBuilder
    private var priorityDot: some View {
        switch task.priority {
        case .high:
            Circle().fill(.apexRed).frame(width: 6, height: 6)
        case .medium:
            Circle().fill(.apexOrange).frame(width: 6, height: 6)
        case .low:
            EmptyView()
        }
    }
}
