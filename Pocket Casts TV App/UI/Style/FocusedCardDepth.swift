import SwiftUI

/// How the focused-card highlight renders. Both styles share the same drop shadow;
/// they differ in what they paint on top of the card.
enum FocusedCardStyle {
    /// Full diagonal specular sheen across the whole face. Use on cards that are
    /// mostly artwork or a flat colour (`DiscoverCategoryCell`, `PlaylistCell`,
    /// `DiscoverFeaturedPodcastCell`) where the sheen has nothing to muddy.
    case surface

    /// Thin inner edge highlight only — a lit top edge and a subtle rim line at the
    /// bottom, with the body of the card left untouched. Use on cards that pair a
    /// cover with text (`EpisodeRow`, `NowPlayingRow`, `DiscoverVideoEpisodeCell`)
    /// so the highlight doesn't wash artwork or text. Closer to how tvOS handles
    /// focus on content-heavy cards.
    case content
}

extension View {
    /// Apple-TV-style depth for focused cards: a soft drop shadow plus a focus
    /// highlight whose shape depends on `style` — see ``FocusedCardStyle``.
    ///
    /// Apply after the card's `.clipShape(...)` so the shadow draws outside the
    /// clipped surface and the highlight is inset to match.
    func focusedCardDepth(
        isFocused: Bool,
        cornerRadius: CGFloat = 12,
        style: FocusedCardStyle = .surface
    ) -> some View {
        modifier(FocusedCardDepth(isFocused: isFocused, cornerRadius: cornerRadius, style: style))
    }

    /// Variant that picks up `\.isFocused` from the surrounding environment. Use
    /// directly inside a `Button` / `NavigationLink` label so call sites that
    /// don't already track focus don't need a wrapper struct just to read it.
    func focusedCardDepth(
        cornerRadius: CGFloat = 12,
        style: FocusedCardStyle = .surface
    ) -> some View {
        modifier(EnvironmentFocusedCardDepth(cornerRadius: cornerRadius, style: style))
    }
}

private struct EnvironmentFocusedCardDepth: ViewModifier {
    @Environment(\.isFocused) private var isFocused
    let cornerRadius: CGFloat
    let style: FocusedCardStyle

    func body(content: Content) -> some View {
        content.focusedCardDepth(isFocused: isFocused, cornerRadius: cornerRadius, style: style)
    }
}

private struct FocusedCardDepth: ViewModifier {
    let isFocused: Bool
    let cornerRadius: CGFloat
    let style: FocusedCardStyle

    func body(content: Content) -> some View {
        content
            .overlay {
                highlight
                    .opacity(isFocused ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .shadow(
                color: .black.opacity(isFocused ? 0.85 : 0),
                radius: isFocused ? 60 : 0,
                x: 0,
                y: isFocused ? 36 : 0
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    @ViewBuilder
    private var highlight: some View {
        switch style {
        case .surface:
            // Two stacked passes: a `.plusLighter` glint that's purely additive
            // (always brightens, never darkens, so it pops on any underlying
            // colour) and an `.overlay` falloff that adds bottom-trailing depth.
            // `.overlay` on its own caps highlight intensity against busy
            // artwork; splitting them out gives a stronger specular feel.
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.28), location: 0.0),
                                .init(color: .white.opacity(0.12), location: 0.20),
                                .init(color: .white.opacity(0.04), location: 0.40),
                                .init(color: .clear, location: 0.60)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.40),
                                .init(color: .black.opacity(0.16), location: 0.85),
                                .init(color: .black.opacity(0.30), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
            }

        case .content:
            // Thin inner stroke that catches light along the top edge and lays a
            // subtle rim shadow along the bottom — leaves the body of the card
            // alone so artwork and text don't get muddied.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.55), location: 0.0),
                            .init(color: .white.opacity(0.10), location: 0.25),
                            .init(color: .clear, location: 0.55),
                            .init(color: .black.opacity(0.22), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
                .blendMode(.overlay)
        }
    }
}
