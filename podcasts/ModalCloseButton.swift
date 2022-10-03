import SwiftUI

struct ModalCloseButton: View {
    @EnvironmentObject var theme: Theme

    var action: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
                ZStack {
                    Circle()
                        .foregroundColor(Color(ThemeColor.primaryInteractive01(for: theme.activeTheme)))
                    Image("close")
                        .foregroundColor(Color(ThemeColor.primaryInteractive02(for: theme.activeTheme)))
                        .accessibilityLabel(L10n.close)
                }
                .frame(width: 30, height: 30)
            }
            .padding(.trailing, 20)
        }
    }
}

struct ModalCloseButton_swift_Previews: PreviewProvider {
    static var previews: some View {
        ModalCloseButton {}
            .environmentObject(Theme(previewTheme: .light))
    }
}
