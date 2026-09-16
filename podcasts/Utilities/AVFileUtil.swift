import AVFoundation
import UIKit

class AVFileUtil: NSObject {
    private var durationHandler: (TimeInterval) -> Void
    private var titleHandler: (String?) -> Void
    private var artworkHandler: (UIImage?) -> Void
    private var url: URL
    private var asset: AVURLAsset
    static let min_artwork_size = 100

    init(fileURL: URL, durationHandler: @escaping ((TimeInterval) -> Void), titleHandler: @escaping ((String?) -> Void), artworkHandler: @escaping ((UIImage?) -> Void)) {
        url = fileURL
        asset = AVURLAsset(url: url)
        self.durationHandler = durationHandler
        self.artworkHandler = artworkHandler
        self.titleHandler = titleHandler

        super.init()

        loadMetaData()
    }

    func loadMetaData() {
        Task {
            let metadata = try? await asset.load(.commonMetadata)
            await processTitle(metadata ?? [])
            if let metadata {
                await processArtwork(metadata)
            }
        }

        // do duration separately as it takes longer
        Task {
            if let duration = try? await asset.load(.duration) {
                durationHandler(CMTimeGetSeconds(duration))
            }
        }
    }

    private func processTitle(_ metadata: [AVMetadataItem]) async {
        let titleMetaData = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: AVMetadataIdentifier.commonIdentifierTitle)

        if let metaData = titleMetaData.first {
            if let title = try? await metaData.load(.stringValue), !title.isEmpty {
                titleHandler(title)
                return
            }
        }
        titleHandler(nil)
    }

    private func processArtwork(_ metadata: [AVMetadataItem]) async {
        let artworks = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common)
        var artworkImages = [UIImage]()

        for item in artworks {
            var embeddedImage: UIImage

            if let data = try? await item.load(.dataValue), SJMediaMetadataHelper.isValidEmbeddedImage(data), let image = UIImage(data: data) {
                embeddedImage = image
                artworkImages.append(embeddedImage)
            }
        }

        var biggestImage: UIImage?
        if artworkImages.isEmpty {
            artworkHandler(nil)
            return
        } else if artworkImages.count == 1 {
            biggestImage = artworkImages.first
        } else {
            for image in artworkImages {
                if biggestImage == nil {
                    biggestImage = image
                } else {
                    if image.size.height > (biggestImage?.size.height ?? 0) || image.size.width > (biggestImage?.size.width ?? 0) {
                        biggestImage = image
                    }
                }
            }
        }

        if let biggest = biggestImage, biggest.size.width >= CGFloat(AVFileUtil.min_artwork_size) {
            artworkHandler(biggest)
        } else {
            artworkHandler(nil)
        }
    }
}
