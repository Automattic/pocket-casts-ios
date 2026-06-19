import SwiftUI

extension View {
    /// Apple-TV-style depth for focused cards: a soft drop shadow that lifts the card
    /// off the page, plus a subtle diagonal sheen that mimics light hitting the surface.
    ///
    /// Apply after the card's `.clipShape(...)` / `.clipped()` so the shadow draws outside
    /// the clipped surface. The sheen overlay is inset to match the clip.
    func focusedCardDepth(isFocused: Bool, cornerRadius: CGFloat = 12) -> some View {
        modifier(FocusedCardDepth(isFocused: isFocused, cornerRadius: cornerRadius))
    }
}

private struct FocusedCardDepth: ViewModifier {
    let isFocused: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                // `.overlay` blend mode brightens the white stops and darkens the black ones
                // against whatever sits beneath, so both ends of the gradient contribute.
                // `.plusLighter` would silently swallow the dark side.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.85), location: 0.0),
                                .init(color: .white.opacity(0.45), location: 0.18),
                                .init(color: .white.opacity(0.15), location: 0.40),
                                .init(color: .clear, location: 0.58),
                                .init(color: .black.opacity(0.45), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
                    .opacity(isFocused ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .shadow(
                color: .black.opacity(isFocused ? 0.6 : 0),
                radius: isFocused ? 44 : 0,
                x: 0,
                y: isFocused ? 26 : 0
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
