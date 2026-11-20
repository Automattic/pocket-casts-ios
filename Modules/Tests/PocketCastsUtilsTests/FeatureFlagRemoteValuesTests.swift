import Foundation
import Testing
@testable import PocketCastsUtils

@Suite(.serialized)
final class FeatureFlagRemoteValuesTests {
    private let flags = FeatureFlagMock()
    private let notificationCenter = NotificationCenter()
    private var posts = 0
    private var observer: NSObjectProtocol?

    init() {
        observer = notificationCenter.addObserver(forName: .featureFlagsDidChange, object: nil, queue: nil) { [unowned self] _ in
            posts += 1
        }
    }

    deinit {
        flags.reset()
    }

    @Test func turningAFlagOffPostsOnce() {
        flags.set(.playback2026, value: true)

        let didChange = FeatureFlag.applyRemoteValues({ $0 == FeatureFlag.playback2026.remoteKey ? false : nil }, notificationCenter: notificationCenter)

        #expect(didChange)
        #expect(!FeatureFlag.playback2026.enabled)
        #expect(posts == 1)
    }

    @Test func turningAFlagOnPostsOnce() {
        flags.set(.playback2026, value: false)

        let didChange = FeatureFlag.applyRemoteValues({ $0 == FeatureFlag.playback2026.remoteKey ? true : nil }, notificationCenter: notificationCenter)

        #expect(didChange)
        #expect(FeatureFlag.playback2026.enabled)
        #expect(posts == 1)
    }

    @Test func theSameValueDoesNotPost() {
        flags.set(.playback2026, value: true)

        let didChange = FeatureFlag.applyRemoteValues({ $0 == FeatureFlag.playback2026.remoteKey ? true : nil }, notificationCenter: notificationCenter)

        #expect(!didChange)
        #expect(FeatureFlag.playback2026.enabled)
        #expect(posts == 0)
    }

    @Test func keysWithoutARemoteValueAreLeftAlone() {
        flags.set(.playback2026, value: false)

        let didChange = FeatureFlag.applyRemoteValues({ _ in nil }, notificationCenter: notificationCenter)

        #expect(!didChange)
        #expect(!FeatureFlag.playback2026.enabled)
        #expect(posts == 0)
    }

    @Test func changingSeveralFlagsPostsOnce() {
        flags.set(.playback2026, value: true)
        flags.set(.hidePlayedPodcasts, value: true)

        let remote = [FeatureFlag.playback2026.remoteKey!: false, FeatureFlag.hidePlayedPodcasts.remoteKey!: false]
        let didChange = FeatureFlag.applyRemoteValues({ remote[$0] }, notificationCenter: notificationCenter)

        #expect(didChange)
        #expect(!FeatureFlag.playback2026.enabled)
        #expect(!FeatureFlag.hidePlayedPodcasts.enabled)
        #expect(posts == 1)
    }
}
