import XCTest

@testable import podcasts

final class BouncyButtonFollowLabelTests: XCTestCase {
    func testFollowLabelsNameThePodcast() {
        let button = BouncyButton()

        button.setFollowAccessibilityLabels(podcastTitle: "This American Life")

        XCTAssertEqual(button.accessibilityLabel, "Follow This American Life")
        button.currentlyOn = true
        XCTAssertEqual(button.accessibilityLabel, "Unfollow This American Life")
    }

    func testFollowLabelsUpdateWhenTheButtonIsReused() {
        let button = BouncyButton()
        button.setFollowAccessibilityLabels(podcastTitle: "This American Life")
        button.currentlyOn = true

        button.setFollowAccessibilityLabels(podcastTitle: "Radiolab")

        XCTAssertEqual(button.accessibilityLabel, "Unfollow Radiolab")
    }

    func testFollowLabelsFallBackToGenericLabelsWithoutATitle() {
        let button = BouncyButton()

        button.setFollowAccessibilityLabels(podcastTitle: nil)
        XCTAssertEqual(button.accessibilityLabel, "Follow")

        button.setFollowAccessibilityLabels(podcastTitle: "")
        XCTAssertEqual(button.accessibilityLabel, "Follow")
    }
}
