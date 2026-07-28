import SwiftUI

struct ModalMessageView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var theme: Theme

    let icon: String?
    let title: String
    let message: String
    let destructive: Bool
    let actionTitle: String
    let action: (() -> Void)?

    init(icon: String? = nil, title: String, message: String, destructive: Bool = false, actionTitle: String, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.destructive = destructive
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            if let icon {
                Image(icon)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 36, height: 36)
                    .foregroundColor(theme.primaryInteractive01)
            }
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
