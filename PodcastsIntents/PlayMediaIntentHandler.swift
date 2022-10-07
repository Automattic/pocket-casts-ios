import CoreSpotlight
import Intents
import MediaPlayer
import UIKit

class PlayMediaIntentHandler: NSObject, INPlayMediaIntentHandling {
    func handle(intent: INPlayMediaIntent, completion: @escaping (INPlayMediaIntentResponse) -> Void) {
        let userActivity = NSUserActivity(activityType: "au.com.shiftyjelly.podcasts")
        var trackName = "Playing the top episode"
        if let item = intent.mediaItems?.first, let itemTitle = item.title {
            trackName = itemTitle
        }

        // Donate as User Activity
        userActivity.isEligibleForSearch = true
        userActivity.title = "Play \(trackName)"

        userActivity.isEligibleForPrediction = true
        userActivity.suggestedInvocationPhrase = "Play \(trackName)"
        let attributes = CSSearchableItemAttributeSet(itemContentType: kCGImageAuxiliaryDataTypePortraitEffectsMatte as String)
        userActivity.contentAttributeSet = attributes
        userActivity.becomeCurrent()
        let response = INPlayMediaIntentResponse(code: INPlayMediaIntentResponseCode.handleInApp, userActivity: userActivity)
        response.nowPlayingInfo = [
            MPMediaItemPropertyTitle: trackName,
            MPMediaItemPropertyPlaybackDuration: 30,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0
        ]

        completion(response)
    }

    func resolveMediaItems(for intent: INPlayMediaIntent, with completion: @escaping ([INPlayMediaMediaItemResolutionResult]) -> Void) {
        if let existingItem = intent.mediaItems?.first {
            completion([INPlayMediaMediaItemResolutionResult.success(with: existingItem)])
        } else if let searchItem = intent.mediaSearch?.mediaName {
            if let matchedPodcast = SiriPodcastSearchManager().matchUtteranceToPodcast(searchString: searchItem) {
                let mediaItem = INMediaItem(identifier: matchedPodcast.uuid,
                                            title: matchedPodcast.name,
                                            type: .podcastEpisode,
                                            artwork: nil)
                completion([INPlayMediaMediaItemResolutionResult.success(with: mediaItem)])
            } else {
                completion([INPlayMediaMediaItemResolutionResult.unsupported()])
            }
        } else { // No search terms means the user said "play pocketcasts"
            let currentEpisodeTitle = currentlyPlayingEpisodeTitle() ?? ""
            let resumeItem = INMediaItem(identifier: "Resume ID",
                                         title: currentEpisodeTitle,
                                         type: .podcastEpisode,
                                         artwork: nil)
            completion([INPlayMediaMediaItemResolutionResult.success(with: resumeItem)])
        }
    }

    private func currentlyPlayingEpisodeTitle() -> String? {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId) else { return nil }

        guard let upNextData = sharedDefaults.object(forKey: SharedConstants.GroupUserDefaults.upNextItems) as? Data else {
            return nil
        }

        do {
            let deserializedData = try JSONDecoder().decode([CommonUpNextItem].self, from: upNextData)

            guard deserializedData.count > 0 else { return nil }

            let episodes = deserializedData
            guard let nowPlayingEpisode = episodes.first else { return nil }
            return nowPlayingEpisode.episodeTitle
        } catch {
            return nil
        }
    }

    func resolvePlaybackSpeed(for intent: INPlayMediaIntent, with completion: @escaping (INPlayMediaPlaybackSpeedResolutionResult) -> Void) {
        guard let speed = intent.playbackSpeed else {
            completion(INPlayMediaPlaybackSpeedResolutionResult.notRequired())
            return
        }

        if speed > SharedConstants.PlaybackEffects.maximumPlaybackSpeed {
            completion(INPlayMediaPlaybackSpeedResolutionResult.unsupported(forReason: .aboveMaximum))
        } else if speed < SharedConstants.PlaybackEffects.minimumPlaybackSpeed {
            completion(INPlayMediaPlaybackSpeedResolutionResult.unsupported(forReason: .belowMinimum))
        } else {
            let result = INDoubleResolutionResult.success(with: speed)
            completion(INPlayMediaPlaybackSpeedResolutionResult(doubleResolutionResult: result))
        }
    }

    func resolveResumePlayback(for intent: INPlayMediaIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.success(with: true))
    }
}
