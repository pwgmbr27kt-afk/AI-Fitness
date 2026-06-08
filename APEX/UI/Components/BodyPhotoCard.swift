import SwiftUI

struct BodyPhotoCard: View {
    var entry: BodyEntry
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            GlassCard(padding: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Photo placeholder or actual image
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(Color.apexSurface)
                            .frame(height: 120)

                        if let data = entry.photoFront, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundStyle(.apexTextTertiary)
                                Text("Kein Foto")
                                    .font(.apexCaption)
                                    .foregroundStyle(.apexTextTertiary)
                            }
                        }
                    }

                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.apexCallout)
                        .foregroundStyle(.apexTextSecondary)

                    Text(String(format: "%.1f kg", entry.weightKg))
                        .font(.apexHeadline)
                        .foregroundStyle(.apexTextPrimary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
