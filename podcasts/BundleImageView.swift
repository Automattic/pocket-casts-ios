import UIKit

class BundleImageView: PodcastImageView {
    func setBundleImageUrl(url: String, size: PodcastThumbnailSize) {
        guard let imageView else { return }

        ImageManager.sharedManager.loadBundleImage(imageUrl: url, imageView: imageView, placeholderSize: size)
        adjustForSize(size)
    }
}
