import SwiftUI
import Kingfisher

struct PodcastImage: View {
    let uuid: String
    let size: PodcastThumbnailSize
    let contentMode: SwiftUI.ContentMode
    let aspectRatio: CGFloat?

    init(uuid: String, size: PodcastThumbnailSize = .list, aspectRatio: CGFloat? = 1, contentMode: SwiftUI.ContentMode = .fit) {
        self.uuid = uuid
        self.size = size
        self.contentMode = contentMode
        self.aspectRatio = aspectRatio
    }

    var body: some View {
        KFImage(ImageManager.sharedManager.podcastUrl(imageSize: size, uuid: uuid))
            .placeholder { _ in
                if let placeholder = ImageManager.sharedManager.placeHolderImage(size) {
                    Image(uiImage: placeholder)
                        .resizable()
                }
            }
            .resizable()
            .aspectRatio(aspectRatio, contentMode: contentMode)
            .accessibilityHidden(true)
    }
}
