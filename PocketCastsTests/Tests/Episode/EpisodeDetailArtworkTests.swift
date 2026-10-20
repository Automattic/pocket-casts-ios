import XCTest
import UIKit
@testable import podcasts

final class EpisodeDetailArtworkTests: DBTestCase {
    private var originalLoadEmbeddedImages = Settings.loadEmbeddedImages

    override func tearDown() {
        Settings.loadEmbeddedImages = originalLoadEmbeddedImages
        ImageManager.shared.subscribedPodcastsCache.removeImage(forKey: episode.uuid)
        super.tearDown()
    }

    @MainActor
    func testCachedEpisodeArtworkSurvivesDisplayedDataRefresh() {
        originalLoadEmbeddedImages = Settings.loadEmbeddedImages
        Settings.loadEmbeddedImages = true
        let artwork = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
        ImageManager.shared.save(artwork, for: episode.uuid)

        let controller = EpisodeDetailViewController(episode: episode, podcast: podcast, source: .podcastScreen)
        controller.loadViewIfNeeded()
        controller.updateDisplayedData()

        XCTAssertEqual(controller.podcastImage.imageView?.image, artwork)

        controller.updateDisplayedData()

        XCTAssertEqual(controller.podcastImage.imageView?.image, artwork)
    }
}
