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
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.22), location: 0.0),
                                .init(color: .white.opacity(0.04), location: 0.45),
                                .init(color: .black.opacity(0.10), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)
                    .opacity(isFocused ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .shadow(
                color: .black.opacity(isFocused ? 0.45 : 0),
                radius: isFocused ? 32 : 0,
                x: 0,
                y: isFocused ? 20 : 0
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
