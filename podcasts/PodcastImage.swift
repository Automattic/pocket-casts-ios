import SwiftUI
import Kingfisher

struct PodcastImage: View {
    let uuid: String
    let size: PodcastThumbnailSize

    init(uuid: String, size: PodcastThumbnailSize = .list) {
        self.uuid = uuid
        self.size = size
    }

    var body: some View {
        KFImage(ImageManager.sharedManager.podcastUrl(imageSize: size, uuid: uuid))
            .resizable()
            .aspectRatio(1, contentMode: .fit)
            .accessibilityHidden(true)
    }
}
