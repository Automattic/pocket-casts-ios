import SwiftUI

struct ModalView: View {
    public var view: () -> AnyView
    var dismissAction: () -> Void

    var body: some View {
        VStack {
            ModalCloseButton(background: Color.white.opacity(0.2), foreground: Color(ThemeColor.playerContrast01()), action: dismissAction)
            view()
        }
        .padding(.top, 20)
    }
}
