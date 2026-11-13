import SwiftUI

struct FittedPresentationDetent: ViewModifier {
    @State private var height: CGFloat = 300 // used until the first measurement

    func body(content: Content) -> some View {
        ScrollView {
            content
                .fixedSize(horizontal: false, vertical: true) // use the content's ideal height
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { newHeight in
                    height = newHeight
                }
        }
        .applyDefaultThemeOptions()
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([.height(height)])
    }
}

extension View {
    func fittedPresentationDetent() -> some View {
        modifier(FittedPresentationDetent())
    }
}
