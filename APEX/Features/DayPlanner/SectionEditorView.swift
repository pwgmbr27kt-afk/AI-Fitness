import SwiftUI
import SwiftData

struct SectionEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var section: DaySection?   // nil = create new

    @State private var name = ""
    @State private var icon = "star.fill"
    @State private var colorHex = "#00D4FF"

    private let iconOptions = [
        "sunrise.fill", "sun.max.fill", "sunset.fill", "moon.stars.fill",
        "star.fill", "bolt.fill", "heart.fill", "flame.fill",
        "dumbbell.fill", "fork.knife", "drop.fill", "figure.flexibility"
    ]

    private let colorOptions = [
        "#00D4FF", "#007AFF", "#9B59B6", "#4CAF50",
        "#FF9800", "#F44336", "#FFD700", "#FFB347"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.apexBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Preview
                        HStack(spacing: Spacing.md) {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(Color(hex: colorHex))
                            Text(name.isEmpty ? "Vorschau" : name)
                                .font(.apexHeadline)
                                .foregroundStyle(.apexTextPrimary)
                            Spacer()
                        }
                        .padding(Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.lg)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: Radius.lg)
                                        .stroke(Color(hex: colorHex).opacity(0.4), lineWidth: 1)
                                }
                        }

                        // Name
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Name")
                                    .font(.apexCallout)
                                    .foregroundStyle(.apexTextSecondary)
                                TextField("z.B. Morgen", text: $name)
                                    .font(.apexBody)
                                    .foregroundStyle(.apexTextPrimary)
                            }
                        }

                        // Icon picker
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Icon")
                                    .font(.apexCallout)
                                    .foregroundStyle(.apexTextSecondary)
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.sm) {
                                    ForEach(iconOptions, id: \.self) { opt in
                                        Button {
                                            icon = opt
                                        } label: {
                                            Image(systemName: opt)
                                                .font(.title3)
                                                .foregroundStyle(icon == opt ? .black : .apexTextSecondary)
                                                .frame(width: 44, height: 44)
                                                .background {
                                                    RoundedRectangle(cornerRadius: Radius.sm)
                                                        .fill(icon == opt ? Color.apexCyan : Color.white.opacity(0.06))
                                                }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Color picker
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Farbe")
                                    .font(.apexCallout)
                                    .foregroundStyle(.apexTextSecondary)
                                HStack(spacing: Spacing.md) {
                                    ForEach(colorOptions, id: \.self) { hex in
                                        Button {
                                            colorHex = hex
                                        } label: {
                                            Circle()
                                                .fill(Color(hex: hex))
                                                .frame(width: 32, height: 32)
                                                .overlay {
                                                    if colorHex == hex {
                                                        Circle().stroke(.white, lineWidth: 2)
                                                        Image(systemName: "checkmark")
                                                            .font(.caption.bold())
                                                            .foregroundStyle(.white)
                                                    }
                                                }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .apexPadding()
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle(section == nil ? "Neuer Bereich" : "Bereich bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }.foregroundStyle(.apexTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .foregroundStyle(name.isNotEmpty ? .apexCyan : .apexTextTertiary)
                        .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let s = section {
                    name     = s.name
                    icon     = s.icon
                    colorHex = s.colorHex
                }
            }
        }
    }

    private func save() {
        if let s = section {
            s.name     = name
            s.icon     = icon
            s.colorHex = colorHex
        } else {
            let newSection = DaySection(name: name, icon: icon, sortOrder: 999, colorHex: colorHex)
            context.insert(newSection)
        }
        try? context.save()
        dismiss()
    }
}
