import SwiftUI
import Kingfisher
import PocketCastsServer

struct LoginLandingCoverImage: View {
    /// UUID of the podcast to load the cover
    let podcastUuid: String

    /// The color of the view the cover will appear on
    /// Prevents a flickering issue on dark backgrounds
    let viewBackgroundStyle: ThemeStyle?

    private let image: UIImage

    init(podcastUuid: String, viewBackgroundStyle: ThemeStyle? = nil, placeholderImage: String) {
        self.podcastUuid = podcastUuid
        self.viewBackgroundStyle = viewBackgroundStyle

        let cachedImage = Self.cachedImage(for: podcastUuid)

        if let cachedImage {
            self.image = cachedImage
        } else if let image = UIImage(named: placeholderImage) {
            self.image = image
        } else {
            self.image = UIImage()
        }
    }

    /// Helper function to return whether or not we will have a cached image for the podcast
    static func hasCache(for uuid: String) -> Bool {
        if ImageManager.sharedManager.hasCachedImage(for: uuid, size: .grid) {
            return true
        }

        let key = ImageManager.sharedManager.podcastUrl(imageSize: .grid, uuid: uuid).absoluteString
        return ImageCache.default.isCached(forKey: key)
    }

    /// Attempt to find a cached image for the given podcast UUID
    private static func cachedImage(for uuid: String) -> UIImage? {
        // Check the subscribed cached
        if let cachedImage = ImageManager.sharedManager.cachedImageFor(podcastUuid: uuid, size: .grid) {
            return cachedImage
        }

        // The key is the URL string
        let key = ImageManager.sharedManager.podcastUrl(imageSize: .grid, uuid: uuid).absoluteString

        // Check the default cache
        guard ImageCache.default.isCached(forKey: key) else {
            return nil
        }

        // Get the path of the potentially cached image
        let path = ImageCache.default.cachePath(forKey: key)
        return UIImage(contentsOfFile: path)
    }

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .cornerRadius(8)
            .modifier(BigCoverShadow())
    }
}
