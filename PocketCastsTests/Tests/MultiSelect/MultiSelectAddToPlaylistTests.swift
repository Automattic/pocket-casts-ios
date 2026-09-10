@testable import podcasts
import PocketCastsDataModel
import UIKit
import XCTest

/// PCIOS-945: "Add to Playlist" was the one multi-select action that never finished, so the
/// mode — and with it the hidden tab bar and mini player — stayed on after the chooser closed.
@MainActor
final class MultiSelectAddToPlaylistTests: XCTestCase {
    func testFinishingInTheChooserEndsMultiSelect() {
        let delegate = MultiSelectActionDelegateMock(selected: [Episode()])

        let chooser = MultiSelectHelper.makeAddToPlaylistChooser(actionDelegate: delegate)
        XCTAssertNotNil(chooser)

        chooser?.onCompletion?()

        XCTAssertEqual(delegate.completedCount, 1)
    }

    func testMultiSelectStaysOnUntilTheChooserFinishes() {
        let delegate = MultiSelectActionDelegateMock(selected: [Episode()])

        _ = MultiSelectHelper.makeAddToPlaylistChooser(actionDelegate: delegate)

        XCTAssertEqual(delegate.completedCount, 0, "Presenting the chooser isn't the action completing")
    }

    func testTheChooserKeepsNoStrongHoldOnTheScreen() {
        var delegate: MultiSelectActionDelegateMock? = MultiSelectActionDelegateMock(selected: [Episode()])
        weak var weakDelegate = delegate

        let chooser = MultiSelectHelper.makeAddToPlaylistChooser(actionDelegate: delegate!)
        delegate = nil

        XCTAssertNil(weakDelegate)
        chooser?.onCompletion?()
    }

    func testFilesCantBeAddedToAPlaylist() {
        let delegate = MultiSelectActionDelegateMock(selected: [Episode(), UserEpisode()])

        XCTAssertNil(MultiSelectHelper.makeAddToPlaylistChooser(actionDelegate: delegate))
        XCTAssertEqual(delegate.completedCount, 0)
    }

    func testAnEmptySelectionHasNothingToAdd() {
        let delegate = MultiSelectActionDelegateMock(selected: [])

        XCTAssertNil(MultiSelectHelper.makeAddToPlaylistChooser(actionDelegate: delegate))
    }

    func testASelectionOverThePlaylistLimitIsRejected() {
        let overTheLimit = (0...Constants.Limits.maxFilterItems).map { _ in Episode() }
        let delegate = MultiSelectActionDelegateMock(selected: overTheLimit)

        XCTAssertNil(MultiSelectHelper.makeAddToPlaylistChooser(actionDelegate: delegate))
        XCTAssertEqual(delegate.completedCount, 0)
    }
}

@MainActor
private final class MultiSelectActionDelegateMock: MultiSelectActionDelegate {
    private let selected: [BaseEpisode]
    private let presentingViewController = UIViewController()

    private(set) var completedCount = 0

    init(selected: [BaseEpisode]) {
        self.selected = selected
    }

    func multiSelectPresentingViewController() -> UIViewController {
        presentingViewController
    }

    func multiSelectedBaseEpisodes() -> [BaseEpisode] {
        selected
    }

    func multiSelectedPlayListEpisodes() -> [PlaylistEpisode]? {
        nil
    }

    func multiSelectActionBegan(status: String) {}

    func multiSelectActionCompleted() {
        completedCount += 1
    }

    var multiSelectViewSource: AnalyticsSource { .downloads }
}
