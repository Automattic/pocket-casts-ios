import SwiftUI
import PocketCastsServer

struct PodcastCover: View {
    /// UUID of the podcast to load the cover
    let podcastUuid: String

    /// Whether this is a big cover, in which shadows should be bigger
    let big: Bool

    init(podcastUuid: String, big: Bool = false) {
        self.podcastUuid = podcastUuid
        self.big = big
    }

    var body: some View {
        ZStack {
            if big {
                Rectangle()
                    .modifier(BigCoverShadow())
            } else {
                Rectangle()
                    .modifier(NormalCoverShadow())
            }


            ImageView(ServerHelper.imageUrl(podcastUuid: podcastUuid, size: 280))
                .cornerRadius(big ? 8 : 4)
        }
    }
}

/// Apply shadow and radius to podcast cover
struct NormalCoverShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(4)
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            .shadow(color: .black.opacity(0.09), radius: 3, x: 0, y: 3)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 6)
            .shadow(color: .black.opacity(0.01), radius: 4, x: 0, y: 11)
            .accessibilityHidden(true)
    }
}

/// Apply shadow and radius to podcast cover
struct BigCoverShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 9, x: 0, y: 4)
            .shadow(color: .black.opacity(0.09), radius: 17, x: 0, y: 17)
            .shadow(color: .black.opacity(0.05), radius: 23, x: 0, y: 38)
            .shadow(color: .black.opacity(0.01), radius: 27, x: 0, y: 67)
            .accessibilityHidden(true)
    }
}
