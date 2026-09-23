import SwiftUI

struct BlurredCoverBackground<Background: View>: ViewModifier {
    let size: CGFloat
    let radius: CGFloat
    let scale: CGFloat
    let offset: CGFloat

    @ViewBuilder let background: Background

    func body(content: Content) -> some View {
        content
            .background(alignment: .topLeading) {
                background
                    .frame(width: size * scale, height: size * scale)
                    .blur(radius: radius)
                    .opacity(0.7)
                    .offset(x: size * offset, y: size * offset)
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    func blurredCoverBackground<Background: View>(size: CGFloat,
                                                  radius: CGFloat = 100,
                                                  scale: CGFloat = 1.5,
                                                  offset: CGFloat = -0.5,
                                                  @ViewBuilder _ background: () -> Background) -> some View {
        modifier(BlurredCoverBackground(size: size, radius: radius, scale: scale, offset: offset, background: background))
    }
}
