import SwiftUI

struct SubscriptionInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 48) {
            HStack(spacing: 16) {
                Text("")
                    .font(.title2)
                    .foregroundStyle(Color.pcTextPrimary)
                Spacer()
                Text("")
                    .font(.body)
                    .foregroundStyle(Color.pcTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: 800)
        .padding(80)
    }
}
