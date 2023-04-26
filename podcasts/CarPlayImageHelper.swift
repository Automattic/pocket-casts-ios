import CarPlay
import Foundation
import Kingfisher
import PocketCastsDataModel

class CarPlayImageHelper {
    static var imageCache = ImageCache(name: "carplay_cache")
    static var carTraitCollection: UITraitCollection?

    class func imageForPodcast(_ podcast: Podcast, maxSize: CGSize = CPListItem.maximumImageSize) -> UIImage {
        let cacheKey = podcast.uuid

        if let cachedImage = cachedImage(for: cacheKey, maxSize: maxSize) {
            return cachedImage
        }

        let image = ImageManager.sharedManager.cachedImageFor(podcastUuid: podcast.uuid, size: .list) ?? UIImage(named: "noartwork-grid-dark")!

        let adjustedImage = adjustImageIfRequired(image: image)
        cacheImage(adjustedImage, for: cacheKey, maxSize: maxSize)
        return adjustedImage
    }

    class func imageForFolder(_ folder: Folder) -> UIImage {
        /// sj_snapshotImage is failing to generate the preview (artworks won't appear)
        /// A workaround is to wrap the view in a UIStackView. This prevents the folder
        /// image from being rendered without the artworks.
        let previewWrapper = UIStackView(frame: Constants.folderPreviewSize)
        let preview = FolderPreviewView(frame: Constants.folderPreviewSize)
        preview.showFolderName = false
        preview.forCarPlay = true
        preview.populateFrom(folder: folder)
        previewWrapper.addArrangedSubview(preview)
        previewWrapper.layoutSubviews()

        let image = previewWrapper.sj_snapshotImage(afterScreenUpdate: true, opaque: true) ?? UIImage(named: "noartwork-grid-dark")!

        return adjustImageIfRequired(image: image)
    }

    class func imageForEpisode(_ episode: BaseEpisode, maxSize: CGSize = CPListItem.maximumImageSize) -> UIImage {
        let cacheKey = episode.cacheKey

        if let cachedImage = cachedImage(for: cacheKey, maxSize: maxSize) {
            return cachedImage
        }

        var image: UIImage?
        if let episode = episode as? Episode {
            image = ImageManager.sharedManager.cachedImageFor(podcastUuid: episode.podcastUuid, size: .list)
        } else if let userEpisode = episode as? UserEpisode {
            image = ImageManager.sharedManager.cachedImageForUserEpisode(episode: userEpisode, size: .list)
        }

        let adjustedImage = adjustImageIfRequired(image: image ?? UIImage(named: "noartwork-list-dark")!, maxSize: maxSize)
        cacheImage(adjustedImage, for: cacheKey, maxSize: maxSize)
        return adjustedImage
    }

    private class func adjustImageIfRequired(image: UIImage, maxSize: CGSize = CPListItem.maximumImageSize) -> UIImage {
        guard let carTraitCollection else { return image }
        return image.carPlayImage(with: carTraitCollection, maxSize: maxSize)
    }

    private static func cachedImage(for key: String, maxSize: CGSize) -> UIImage? {
        let cacheKey = "\(key)_\(maxSize.width)"

        // Check the memory and disk cache
        guard imageCache.isCached(forKey: cacheKey) else { return nil }

        // Try to get from memory first
        if let image = imageCache.retrieveImageInMemoryCache(forKey: cacheKey) {
            return image
        }

        var cachedImage: UIImage? = nil

        imageCache.retrieveImageInDiskCache(forKey: cacheKey, options: [.loadDiskFileSynchronously]) { result in
            switch result {
            case let .success(image):
                cachedImage = image
            default: break
            }
        }

        guard let cachedImage else { return nil }

        // When the image is loaded from disk the scale/etc gets reset, so update it again
        let processedImage = cachedImage.carPlayImage(with: carTraitCollection ?? .current, maxSize: maxSize)

        // Store the processed image in memory again
        imageCache.store(processedImage, forKey: cacheKey, toDisk: false)
        return processedImage
    }

    private static func cacheImage(_ image: UIImage, for key: String, maxSize: CGSize) {
        let cacheKey = "\(key)_\(maxSize.width)"

        imageCache.store(image, forKey: cacheKey)
    }

    private enum Constants {
        static let folderPreviewSize: CGRect = .init(x: 0, y: 0, width: 240, height: 240)
    }
}

// MARK: - CarPlay Resizing

private extension UIImage {
    /// This will process the image for us and return an image that CarPlay expects for its current traits (ie: scaling)
    func carPlayImage(with traits: UITraitCollection, maxSize: CGSize) -> UIImage {
        let imageAsset = UIImageAsset()
        imageAsset.register(self, with: traits)
        let processedImage = imageAsset.image(with: traits)

        // Don't resize if we don't need to
        if processedImage.size == maxSize {
            return processedImage
        }

        // Scale the image to the max size CarPlay expects
        return processedImage.resizeProportionally(to: maxSize, displayScale: traits.displayScale)
    }
}

private extension BaseEpisode {
    var cacheKey: String {
        if let episode = self as? Episode {
            return episode.podcastUuid
        }

        if let userEpisode = self as? UserEpisode {
            return userEpisode.urlForImage().absoluteString
        }

        return uuid
    }
}
