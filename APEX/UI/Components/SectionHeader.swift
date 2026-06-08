import SwiftUI

struct SectionHeader: View {
    var title: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.apexHeadline)
                .foregroundStyle(.apexTextPrimary)
            Spacer()
            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.apexCallout)
                        .foregroundStyle(.apexCyan)
                }
            }
        }
    }
}
