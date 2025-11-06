import SwiftUI
import Kingfisher

struct AsyncImageView: View {
    private let url: URL
    private let cacheKey: String?
    private let cache: ImageCache
    private let placeholder: Image?
    private let contentMode: SwiftUI.ContentMode
    private let aspectRatio: CGFloat?

    init(
        url: URL,
        cacheKey: String? = nil,
        cache: ImageCache = ImageManager.sharedManager.subscribedPodcastsCache,
        placeholder: Image? = nil,
        aspectRatio: CGFloat? = 1,
        contentMode: SwiftUI.ContentMode = .fit
    ) {
        self.url = url
        self.cacheKey = cacheKey
        self.cache = cache
        self.placeholder = placeholder
        self.contentMode = contentMode
        self.aspectRatio = aspectRatio
    }

    var body: some View {
        let resource = KF.ImageResource(downloadURL: url, cacheKey: cacheKey)

        KFImage.resource(resource)
            .placeholder { _ in
                if let placeholder {
                    placeholder
                        .resizable()
                }
            }
            .resizable()
            .targetCache(cache)
            .fade(duration: 0.25)
            .aspectRatio(aspectRatio, contentMode: contentMode)
    }
}
