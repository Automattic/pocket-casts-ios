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
        asset.loadValuesAsynchronously(forKeys: [AVMetadataKey.commonKeyTitle.rawValue, AVMetadataKey.commonKeyArtwork.rawValue]) {
            self.processTitle()
            if self.asset.statusOfValue(forKey: AVMetadataKey.commonKeyArtwork.rawValue, error: nil) == .loaded {
                self.processArtwork()
            }
        }

        // do duration seperately as it takes longer. the load function calls the closure
        // only when all keys are available
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            let durationStatus = self.asset.statusOfValue(forKey: "duration", error: nil)
            if durationStatus == .loaded {
                let calculatedDuration = CMTimeGetSeconds(self.asset.duration)
                self.durationHandler(calculatedDuration)
            }
        }
    }

    private func processTitle() {
        let titleMetaData = AVMetadataItem.metadataItems(from: asset.commonMetadata, filteredByIdentifier: AVMetadataIdentifier.commonIdentifierTitle)

        if let metaData = titleMetaData.first {
            if let title = metaData.stringValue, title.count > 0 {
                titleHandler(title)
                return
            }
        }
        titleHandler(nil)
    }

    private func processArtwork() {
        let artworks = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common)
        var artworkImages = [UIImage]()

        for item in artworks {
            var embeddedImage: UIImage

            if let data = item.dataValue, SJMediaMetadataHelper.isValidEmbeddedImage(data), let image = UIImage(data: data) {
                embeddedImage = image
                artworkImages.append(embeddedImage)
            }
        }

        var biggestImage: UIImage?
        if artworkImages.count == 0 {
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
