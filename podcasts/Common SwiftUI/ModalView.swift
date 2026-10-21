import SwiftUI

struct ModalView<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var bottomSafeAreaInset: CGFloat = 0

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
        .padding(.bottom, horizontalSizeClass == .regular ? 20 : max(0, 20 - bottomSafeAreaInset))
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { bottomSafeAreaInset = proxy.safeAreaInsets.bottom }
                    .onChange(of: proxy.safeAreaInsets.bottom) { _, inset in bottomSafeAreaInset = inset }
            }
        }
    }
}
