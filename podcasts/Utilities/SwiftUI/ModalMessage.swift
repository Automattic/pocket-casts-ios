import SwiftUI

struct ModalMessageView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var theme: Theme

    let icon: String
    let title: String
    let message: String
    let destructive: Bool
    let actionTitle: String
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(icon)
                .resizable()
                .renderingMode(.template)
                .frame(width: 36, height: 36)
                .foregroundColor(theme.primaryInteractive01)
            Group {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(theme.primaryText01)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(.body)
                    .foregroundColor(theme.primaryText02)
                    .fixedSize(horizontal: false, vertical: true)
            }.multilineTextAlignment(.center)
            Spacer()
            Button() {
                action?()
                dismiss()
            } label: {
                Text(actionTitle)
                    .textStyle(RoundedButton(destructive: destructive))
            }
            Spacer()
                .frame(maxHeight: 16)
        }
        .padding()
        .applyDefaultThemeOptions()
    }
}
