import SwiftUI
import PocketCastsServer

struct BigPodcastCover: View {
    /// UUID of the podcast to load the cover
    let podcastUuid: String

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.2))
                .modifier(PodcastBigCover())

            ImageView(ServerHelper.imageUrl(podcastUuid: podcastUuid, size: 280))
                .cornerRadius(8)
        }
    }
}

/// Apply shadow and radius to podcast cover
struct PodcastBigCover: ViewModifier {
    func body(content: Content) -> some View {
        content
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 9, x: 0, y: 4)
            .shadow(color: .black.opacity(0.09), radius: 17, x: 0, y: 17)
            .shadow(color: .black.opacity(0.05), radius: 23, x: 0, y: 38)
            .shadow(color: .black.opacity(0.01), radius: 27, x: 0, y: 67)
            .accessibilityHidden(true)
    }
}
