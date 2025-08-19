import SwiftUI

struct FadeGradientModifier: ViewModifier {
    @EnvironmentObject var theme: Theme

    let height: CGFloat
    let opacity: Double
    let isVisible: Bool
    let bottomOffset: CGFloat

    init(
        height: CGFloat = 100,
        opacity: Double = 0.8,
        isVisible: Bool = true,
        bottomOffset: CGFloat = 0
    ) {
        self.height = height
        self.opacity = opacity
        self.isVisible = isVisible
        self.bottomOffset = bottomOffset
    }

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if isVisible {
                LinearGradient(
                    colors: [theme.primaryUi01.opacity(0), theme.primaryUi01],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(opacity)
                .frame(height: height)
                .padding(.bottom, bottomOffset)
                .allowsHitTesting(false)
            }
        }
    }
}

extension View {
    func fadeGradient(
        height: CGFloat = 100,
        opacity: Double = 0.8,
        isVisible: Bool = true,
        bottomOffset: CGFloat = 0
    ) -> some View {
        modifier(
            FadeGradientModifier(
                height: height,
                opacity: opacity,
                isVisible: isVisible,
                bottomOffset: bottomOffset
            )
        )
    }
}
