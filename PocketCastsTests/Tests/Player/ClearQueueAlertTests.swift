import XCTest
@testable import podcasts

final class ClearQueueAlertTests: XCTestCase {
    func testAlertUsesClearUpNextTitleAndMessage() {
        let alert = UpNextViewController.clearQueueAlert(queueCount: 3) {}

        XCTAssertEqual(alert.title, L10n.clearUpNext)
        XCTAssertEqual(alert.message, L10n.clearUpNextMessage)
        XCTAssertEqual(alert.preferredStyle, .alert)
    }

    func testAlertHasCancelAndDestructiveActionsWithPluralCount() {
        let alert = UpNextViewController.clearQueueAlert(queueCount: 3) {}

        XCTAssertEqual(alert.actions.map(\.title), [L10n.cancel, L10n.queueClearEpisodeQueuePlural(3.localized())])
        XCTAssertEqual(alert.actions.map(\.style), [.cancel, .destructive])
    }

    func testAlertDestructiveActionUsesSingularLabelForOneEpisode() {
        let alert = UpNextViewController.clearQueueAlert(queueCount: 1) {}

        XCTAssertEqual(alert.actions.last?.title, L10n.queueClearEpisodeQueueSingular)
    }

    func testMiniPlayerCloseTitleCapitalization() {
        XCTAssertEqual(L10n.miniPlayerClose, "Close and Clear Up Next")
    }
}
