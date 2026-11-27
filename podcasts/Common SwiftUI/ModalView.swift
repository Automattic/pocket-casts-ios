import SwiftUI

struct ModalView<Content: View>: View {
    @ViewBuilder public var content: () -> Content
    var dismissAction: () -> Void

    init(@ViewBuilder _ content: @escaping () -> Content, dismissAction: @escaping () -> Void) {
        self.content = content
        self.dismissAction = dismissAction
    }

    var body: some View {
        VStack {
            ModalCloseButton(background: Color.gray.opacity(0.2), foreground: Color.white.opacity(0.5), action: dismissAction)
            content()
        }
        .padding(.top, 20)
    }
}
