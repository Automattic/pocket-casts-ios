import SwiftUI

/// The square podcast cover used by the horizontal rows on Home, Discover and Search.
/// Reads focus from the environment, so it can be dropped straight into a
/// `NavigationLink` / `Button` label without the call site tracking focus itself.
struct PodcastCoverCard: View {

    enum Layout {
        static let size = CGFloat(250)
        static let cornerRadius = CGFloat(12)
    }

    let uuid: String
    var size: CGFloat = Layout.size

    var body: some View {
        PodcastImage(uuid: uuid, size: .page)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
            .focusedCardDepth(cornerRadius: Layout.cornerRadius, style: .surface)
    }
}
