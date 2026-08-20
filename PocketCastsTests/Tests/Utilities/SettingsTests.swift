import XCTest
@testable import podcasts
@testable import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

final class SettingsTests: XCTestCase {

    private let userDefaultsSuiteName = "PocketCasts-SettingsTests"

    private lazy var defaultPlayerActions: [PlayerAction] = {
        var actions: [PlayerAction] = [
            .addBookmark,
            .markPlayed,
            .effects,
            .sleepTimer,
            .routePicker,
            .shareEpisode,
            .addToPlaylist,
            .download,
            .transcript,
            .goToPodcast,
            .starEpisode,
            .chromecast,
            .archive,
            .videoToggle
        ]
        return actions
    }()

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    func testPlayerActions() throws {
        Settings.updatePlayerActions(PlayerAction.defaultActions.filter { $0.isAvailable }) // Set defaults
        Settings.updatePlayerActions([.addBookmark, .markPlayed])

        XCTAssertEqual(defaultPlayerActions, Settings.playerActions(), "Player actions should include changes from update")
    }

    // MARK: - Encourage Account Creation cadence

    private let eacInterval: TimeInterval = Settings.encourageAccountCreationInterval
    private let eacNow = Date(timeIntervalSince1970: 1_700_000_000)

    func testEncourageAccountCreationIntervalIsSixtyDays() {
        // Pins the shipped cadence so a change to the constant is caught here (the cadence tests
        // below read the same constant, so on their own they'd silently follow a bad value).
        XCTAssertEqual(Settings.encourageAccountCreationInterval, 60 * 24 * 60 * 60)
    }

    func testEncourageAccountCreationWaitsWhenNotEligible() {
        // Even with an elapsed clock, an ineligible user is never shown the modal.
        let decision = Settings.encourageAccountCreationDecision(
            isEligible: false,
            referenceDate: eacNow.addingTimeInterval(-eacInterval * 2),
            now: eacNow,
            interval: eacInterval
        )
        XCTAssertEqual(decision, .wait)
    }

    func testEncourageAccountCreationAnchorsOnFirstEligibleLaunch() {
        // First eligible launch (no reference date yet) anchors the clock instead of showing.
        let decision = Settings.encourageAccountCreationDecision(
            isEligible: true,
            referenceDate: nil,
            now: eacNow,
            interval: eacInterval
        )
        XCTAssertEqual(decision, .anchor)
    }

    func testEncourageAccountCreationWaitsBeforeIntervalElapses() {
        // One second short of the interval should not show yet.
        let decision = Settings.encourageAccountCreationDecision(
            isEligible: true,
            referenceDate: eacNow.addingTimeInterval(-(eacInterval - 1)),
            now: eacNow,
            interval: eacInterval
        )
        XCTAssertEqual(decision, .wait)
    }

    func testEncourageAccountCreationShowsWhenIntervalElapsed() {
        // Exactly at the interval boundary should show.
        let decision = Settings.encourageAccountCreationDecision(
            isEligible: true,
            referenceDate: eacNow.addingTimeInterval(-eacInterval),
            now: eacNow,
            interval: eacInterval
        )
        XCTAssertEqual(decision, .show)
    }

    func testEncourageAccountCreationShowsWhenIntervalWellExceeded() {
        let decision = Settings.encourageAccountCreationDecision(
            isEligible: true,
            referenceDate: eacNow.addingTimeInterval(-eacInterval * 3),
            now: eacNow,
            interval: eacInterval
        )
        XCTAssertEqual(decision, .show)
    }

    func testEncourageAccountCreationReanchorsWhenReferenceIsInTheFuture() {
        // A reference date in the future (backwards device clock / restored skewed backup) must
        // re-anchor rather than suppress the modal indefinitely.
        let decision = Settings.encourageAccountCreationDecision(
            isEligible: true,
            referenceDate: eacNow.addingTimeInterval(eacInterval),
            now: eacNow,
            interval: eacInterval
        )
        XCTAssertEqual(decision, .anchor)
    }
}
