import XCTest

@testable import PocketCastsDataModel
@testable import PocketCastsUtils
@testable import podcasts

class PlaybackCatchUpHelperTests: XCTestCase {
    private let helper = PlaybackCatchUpHelper()

    private let pauseTimeKey = "lastPauseTime"
    private let pausedEpisodeUuidKey = "lastPausedEpisode"
    private let pausedAtKey = "lastPausedAt"
    private let pauseWasInterruptionKey = "lastPauseWasInterruption"

    override func setUpWithError() throws {
        try super.setUpWithError()

        // start from a clean slate so leftovers from other tests or aborted runs can't leak in
        removeHelperUserDefaults()
        UserDefaults.standard.set(true, forKey: Constants.UserDefaults.intelligentPlaybackResumption)
        try FeatureFlagOverrideStore().override(FeatureFlag.interruptionRewind, withValue: true)
    }

    override func tearDown() {
        removeHelperUserDefaults()
        FeatureFlagOverrideStore().resetOverrides()

        super.tearDown()
    }

    private func removeHelperUserDefaults() {
        [pauseTimeKey, pausedEpisodeUuidKey, pausedAtKey, pauseWasInterruptionKey,
         Constants.UserDefaults.intelligentPlaybackResumption, Constants.UserDefaults.interruptionRewindTime].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }

    private func makeEpisode(playedUpTo: Double = 600) -> Episode {
        let episode = EpisodeBuilder().with(playedUpTo: playedUpTo).build()
        episode.uuid = "test-episode-uuid"
        return episode
    }

    private func setLastPauseTime(secondsAgo: TimeInterval) {
        UserDefaults.standard.setValue(Date(timeIntervalSinceNow: -secondsAgo), forKey: pauseTimeKey)
    }

    // MARK: - Interruption rewind

    func testInterruptionRewindAppliesAfterInterruption() {
        let episode = makeEpisode()
        Settings.interruptionRewindTime = 30

        helper.playbackDidPause(of: episode, dueToInterruption: true)

        XCTAssertEqual(helper.adjustStartTimeIfNeeded(for: episode), episode.playedUpTo - 30)
    }

    func testInterruptionRewindDefaultsToFiveSeconds() {
        let episode = makeEpisode()

        helper.playbackDidPause(of: episode, dueToInterruption: true)

        XCTAssertEqual(helper.adjustStartTimeIfNeeded(for: episode), episode.playedUpTo - 5)
    }

    func testInterruptionRewindDoesNotApplyWhenTurnedOff() {
        let episode = makeEpisode()
        Settings.interruptionRewindTime = 0

        helper.playbackDidPause(of: episode, dueToInterruption: true)

        XCTAssertEqual(helper.adjustStartTimeIfNeeded(for: episode), episode.playedUpTo)
    }

    func testInterruptionRewindDoesNotApplyWhenFeatureFlagDisabled() throws {
        let episode = makeEpisode()
        Settings.interruptionRewindTime = 30
        try FeatureFlagOverrideStore().override(FeatureFlag.interruptionRewind, withValue: false)

        helper.playbackDidPause(of: episode, dueToInterruption: true)

        XCTAssertEqual(helper.adjustStartTimeIfNeeded(for: episode), episode.playedUpTo)
    }

    func testInterruptionRewindDoesNotApplyToRegularPauses() {
        let episode = makeEpisode()
        Settings.interruptionRewindTime = 30

        helper.playbackDidPause(of: episode)

        XCTAssertEqual(helper.adjustStartTimeIfNeeded(for: episode), episode.playedUpTo)
    }

    func testInterruptionRewindAppliesWhenIntelligentPlaybackResumptionIsOff() {
        let episode = makeEpisode()
        Settings.interruptionRewindTime = 30
        UserDefaults.standard.set(false, forKey: Constants.UserDefaults.intelligentPlaybackResumption)

        helper.playbackDidPause(of: episode, dueToInterruption: true)

        XCTAssertEqual(helper.adjustStartTimeIfNeeded(for: episode), episode.playedUpTo - 30)
    }

    func testInterruptionRewindDoesNotRewindPastEpisodeStart() {
        let episode = makeEpisode(playedUpTo: 3)
        Settings.interruptionRewindTime = 30

        helper.playbackDidPause(of: episode, dueToInterruption: true)

        XCTAssertEqual(helper.adjustStartTimeIfNeeded(for: episode), 0)
    }

    func testInterruptionRewindDoesNotApplyToADifferentEpisode() {
        let episode = makeEpisode()
        Settings.interruptionRewindTime = 30

        helper.playbackDidPause(of: episode, dueToInterruption: true)

        let otherEpisode = makeEpisode()
        otherEpisode.uuid = "another-episode-uuid"

        XCTAssertEqual(helper.adjustStartTimeIfNeeded(for: otherEpisode), otherEpisode.playedUpTo)
    }

    // MARK: - Combining with the pause length rewind, the larger amount wins and they never stack

    func testLongerPauseLengthRewindWinsOverInterruptionRewind() {
        let episode = makeEpisode()
        Settings.interruptionRewindTime = 5

        helper.playbackDidPause(of: episode, dueToInterruption: true)
        setLastPauseTime(secondsAgo: 25.hours)

        // paused for more than 24 hours, the 30 second pause length rewind beats the 5 second interruption rewind
        XCTAssertEqual(helper.adjustStartTimeIfNeeded(for: episode), episode.playedUpTo - 30)
    }

    func testLongerInterruptionRewindWinsOverPauseLengthRewind() {
        let episode = makeEpisode()
        Settings.interruptionRewindTime = 60

        helper.playbackDidPause(of: episode, dueToInterruption: true)
        setLastPauseTime(secondsAgo: 6.minutes)

        // paused for more than 5 minutes, the 60 second interruption rewind beats the 10 second pause length rewind
        XCTAssertEqual(helper.adjustStartTimeIfNeeded(for: episode), episode.playedUpTo - 60)
    }

    func testRegularPauseAfterInterruptionClearsTheInterruptionRewind() {
        let episode = makeEpisode()
        Settings.interruptionRewindTime = 30

        helper.playbackDidPause(of: episode, dueToInterruption: true)
        helper.playbackDidPause(of: episode)

        // the most recent pause was a regular one, so the earlier interruption must not cause a rewind
        XCTAssertEqual(helper.adjustStartTimeIfNeeded(for: episode), episode.playedUpTo)
    }

    // MARK: - Existing pause length behaviour is unchanged

    func testPauseLengthRewindStillAppliesToRegularPauses() {
        let episode = makeEpisode()

        helper.playbackDidPause(of: episode)
        setLastPauseTime(secondsAgo: 6.minutes)

        XCTAssertEqual(helper.adjustStartTimeIfNeeded(for: episode), episode.playedUpTo - 10)
    }

    func testNoRewindForShortRegularPause() {
        let episode = makeEpisode()

        helper.playbackDidPause(of: episode)

        XCTAssertEqual(helper.adjustStartTimeIfNeeded(for: episode), episode.playedUpTo)
    }
}
