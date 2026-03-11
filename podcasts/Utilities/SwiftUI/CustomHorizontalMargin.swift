import SwiftUI

struct CustomHorizontalMargin: ViewModifier {
    let margin: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.contentMargins(.horizontal, margin, for: .scrollContent)
        } else {
            content
                .safeAreaInset(edge: .trailing) {
                    EmptyView().frame(width: margin)
                }
                .safeAreaInset(edge: .leading) {
                    EmptyView().frame(width: margin)
                }
        }
    }
}

extension View {
    func customHorizontalMargin(margin: CGFloat)
    -> some View {
        modifier(CustomHorizontalMargin(margin: margin))
  }
}
