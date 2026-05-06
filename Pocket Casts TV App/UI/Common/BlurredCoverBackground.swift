import SwiftUI

struct BlurredCoverBackground<Background: View>: ViewModifier {
    let size: CGFloat
    @ViewBuilder let background: Background

    func body(content: Content) -> some View {
        content
            .background(alignment: .topLeading) {
                background
                    .frame(width: size * 1.5, height: size * 1.5)
                    .blur(radius: 100)
                    .opacity(0.7)
                    .offset(x: -(size * 0.5), y: -(size * 0.5))
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    func blurredCoverBackground<Background: View>(size: CGFloat, @ViewBuilder _ background: () -> Background) -> some View {
        modifier(BlurredCoverBackground(size: size, background: background))
    }
}
