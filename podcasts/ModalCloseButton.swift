import SwiftUI

struct ModalCloseButton: View {
    let background: Color?
    let foreground: Color?

    @EnvironmentObject var theme: Theme

    var action: () -> Void

    init(background: Color? = nil, foreground: Color? = nil, action: @escaping () -> Void) {
        self.background = background
        self.foreground = foreground
        self.action = action
    }

    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
                ZStack {
                    Circle()
                        .foregroundColor(background ?? Color(ThemeColor.primaryInteractive01(for: theme.activeTheme)))
                    Image("close")
                        .foregroundColor(foreground ?? Color(ThemeColor.primaryInteractive02(for: theme.activeTheme)))
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
