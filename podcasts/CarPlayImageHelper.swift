import Foundation
import PocketCastsDataModel

class CarPlayImageHelper {
    class func imageForPodcast(_ podcast: Podcast) -> UIImage {
        let image = ImageManager.sharedManager.cachedImageFor(podcastUuid: podcast.uuid, size: .list) ?? UIImage(named: "noartwork-grid-dark")!

        return adjustImageIfRequired(image: image)
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

    class func imageForEpisode(_ episode: BaseEpisode) -> UIImage {
        var image: UIImage?
        if let episode = episode as? Episode {
            image = ImageManager.sharedManager.cachedImageFor(podcastUuid: episode.podcastUuid, size: .list)
        } else if let userEpisode = episode as? UserEpisode {
            image = ImageManager.sharedManager.cachedImageForUserEpisode(episode: userEpisode, size: .list)
        }

        return adjustImageIfRequired(image: image ?? UIImage(named: "noartwork-list-dark")!)
    }

    private class func adjustImageIfRequired(image: UIImage) -> UIImage {
        // CarPlay list rows have a bug where if the scale is 1, it will draw a half size image, so here we make sure to set the scale correctly
        if image.scale == 1, let cgImage = image.cgImage {
            return UIImage(cgImage: cgImage, scale: 2.0, orientation: image.imageOrientation)
        }

        return image
    }

    private enum Constants {
        static let folderPreviewSize: CGRect = .init(x: 0, y: 0, width: 240, height: 240)
    }
}
