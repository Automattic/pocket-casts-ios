import Foundation
import Intents
import JLRoutes
import PocketCastsDataModel
import PocketCastsUtils

extension AppDelegate {
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        handleContinue(userActivity)

        return true
    }

    func handleContinue(_ userActivity: NSUserActivity) {
        if userActivity.activityType == "au.com.shiftyjelly.podcasts" {
            let info = userActivity.userInfo
            if let urlString = info?["url"] as? String, let url = URL(string: urlString) {
                JLRoutes.routeURL(url)
            }
        } else if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            guard
                let incomingURL = userActivity.webpageURL,
                let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
                let path = components.path,
                let controller = SceneHelper.rootViewController(),
                path != "/get"
            else { return }

            // Also pass any query params from the share URL to the server to allow support for episode position handling
            // Ex: ?t=123
            let query = components.query.map { "?\($0)" } ?? ""
            let sharePath = "\(path)\(query)"

            FileLog.shared.addMessage("Opening universal link, path: \(sharePath)")
            openSharePath("social/share/show\(sharePath)", controller: controller, onErrorOpen: incomingURL)
        }

        guard let intent = userActivity.interaction?.intent else { return }

        if let playIntent = intent as? INPlayMediaIntent {
            var urlString: String?

            if let mediaItem = playIntent.mediaItems?.first {
                if mediaItem.identifier == Constants.SiriActions.playFilterId {
                    if let containerId = playIntent.mediaContainer?.identifier {
                        urlString = "pktc://shortcuts/filter/\(containerId)"
                    }
                } else if mediaItem.identifier == Constants.SiriActions.playPodcastId {
                    if let containerId = playIntent.mediaContainer?.identifier {
                        urlString = "pktc://shortcuts/podcast/\(containerId)"
                    }
                } else if mediaItem.identifier == Constants.SiriActions.playSuggestedId {
                    urlString = "pktc://shortcuts/discover"
                }
            }
            // to fix missing media items when called from shortcuts
            else if let container = playIntent.mediaContainer {
                if container.type == .podcastPlaylist {
                    if let containerId = container.identifier {
                        urlString = "pktc://shortcuts/filter/\(containerId)"
                    }
                } else if container.type == .podcastShow {
                    if let containerId = container.identifier {
                        urlString = "pktc://shortcuts/podcast/\(containerId)"
                    }
                }
            }

            if let urlString = urlString, let url = URL(string: urlString) {
                JLRoutes.routeURL(url)
            }
        } else if intent is SJOpenFilterIntent {
            handleOpenFilterIntent(intent: intent as! SJOpenFilterIntent)
        } else if intent is SJChapterIntent {
            handleChapterIntent(intent: intent as! SJChapterIntent)
        } else if intent is SJSleepTimerIntent {
            let timerIntent = intent as! SJSleepTimerIntent
            if let minutes = timerIntent.minutes {
                _ = SiriShortcutsManager.shared.sleepTimer(newTime: Int(truncating: minutes))
            }
        } else if intent is SJExtendSleepTimerIntent {
            let timerIntent = intent as! SJExtendSleepTimerIntent
            if let minutes = timerIntent.minutes {
                _ = SiriShortcutsManager.shared.extendSleepTimer(addTime: Int(truncating: minutes))
            }
        }
    }

    /// This method is called when a user activity is continued via the restoration handler
    /// in `UIApplicationDelegate application(_:continue:restorationHandler:)`
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)
    }

    func application(_ application: UIApplication, handle: INIntent, completionHandler: (INIntentResponse) -> Void) {
        if let handle = handle as? INPlayMediaIntent {
            let responseCode = handlePlayMediaIntent(intent: handle)

            let response = INPlayMediaIntentResponse(code: responseCode, userActivity: nil)
            completionHandler(response)
        }
    }

    func handlePlayMediaIntent(intent: INPlayMediaIntent) -> INPlayMediaIntentResponseCode {
        var thisIntent = intent
        var responseCode: INPlayMediaIntentResponseCode = .continueInApp

        if let firstIdentifier = thisIntent.mediaItems?.first?.identifier, let title = thisIntent.mediaItems?.first?.title, UUID(uuidString: firstIdentifier) != nil {
            // if the phrase "Play <podcast name> on Pocket Casts" is used the identifier will be the podcast uuid instead of
            // Constants.SiriActions.playPodcastId. Fix this by creating the expected intent format
            thisIntent = SiriShortcutsManager.shared.playPodcastIntent(podcastTitle: title, podcastUuid: firstIdentifier) as! INPlayMediaIntent
        }

        if let identifier = thisIntent.mediaItems?.first?.identifier {
            if identifier == Constants.SiriActions.playSuggestedId {
                responseCode = SiriShortcutsManager.shared.playSuggested()
            } else if identifier == Constants.SiriActions.playUpNextId {
                responseCode = SiriShortcutsManager.shared.playUpNext()
            } else if identifier == Constants.SiriActions.playPodcastId {
                if let uuid = thisIntent.mediaContainer?.identifier {
                    responseCode = SiriShortcutsManager.shared.playPodcast(uuid: uuid)
                }
            } else if identifier == Constants.SiriActions.playFilterId {
                if let uuid = intent.mediaContainer?.identifier {
                    responseCode = SiriShortcutsManager.shared.playFilter(uuid: uuid)
                }
            } else if identifier == Constants.SiriActions.playAllFilterId {
                if let uuid = intent.mediaContainer?.identifier {
                    responseCode = SiriShortcutsManager.shared.playAllFilter(uuid: uuid)
                }
            } else if identifier == Constants.SiriActions.pauseId {
                responseCode = SiriShortcutsManager.shared.pausePlayback()
            } else if identifier == Constants.SiriActions.resumeId {
                // Shortcuts is removing the mediaItems for the "Play Podcaast" and "Play filter"
                // actions, still handle them by checking for a mediaContainer. The correct
                // mediaContainer is passed to the app untouched
                if thisIntent.mediaContainer?.type == .podcastPlaylist, let uuid = thisIntent.mediaContainer?.identifier {
                    responseCode = SiriShortcutsManager.shared.playFilter(uuid: uuid)
                } else if thisIntent.mediaContainer?.type == .podcastShow, let uuid = thisIntent.mediaContainer?.identifier {
                    responseCode = SiriShortcutsManager.shared.playPodcast(uuid: uuid)
                } else {
                    responseCode = SiriShortcutsManager.shared.resumePlayback()
                }
            } else if identifier == Constants.SiriActions.nextChapterId {
                responseCode = SiriShortcutsManager.shared.skipToNextChapter()
            } else if identifier == Constants.SiriActions.previousChapterId {
                responseCode = SiriShortcutsManager.shared.skipToPreviousChapter()
            } else {
                responseCode = SiriShortcutsManager.shared.resumePlayback()
            }
        } else { // Shortcuts is removing the mediaItems for these shortcuts, still handle them
            if let container = thisIntent.mediaContainer {
                if container.type == .podcastPlaylist {
                    if let uuid = container.identifier {
                        responseCode = SiriShortcutsManager.shared.playFilter(uuid: uuid)
                    }
                } else if container.type == .podcastShow {
                    if let uuid = container.identifier {
                        responseCode = SiriShortcutsManager.shared.playPodcast(uuid: uuid)
                    }
                }
            }
        }

        // We need to set the playback speed from the intent, but only if the value
        // is not 1. Siri always passes along 1, even if the user did not specify a speed.
        // This may result in incorrectly overriding the existing speed set in the player
        // See https://github.com/Automattic/pocket-casts-ios/issues/41
        if let spokenSpeed = thisIntent.playbackSpeed, spokenSpeed != 1.0, responseCode == .success {
            let effects = PlaybackManager.shared.effects()
            effects.playbackSpeed = spokenSpeed

            PlaybackManager.shared.changeEffects(effects)
            PlaybackManager.shared.play()
        }

        return responseCode
    }

    func handleChapterIntent(intent: INIntent) {
        if intent is SJChapterIntent {
            let chapterIntent = intent as! SJChapterIntent
            if chapterIntent.skipForward == .next {
                _ = SiriShortcutsManager.shared.skipToNextChapter()
            } else if chapterIntent.skipForward == .previous {
                _ = SiriShortcutsManager.shared.skipToPreviousChapter()
            }
        } else {
            // Fallback on earlier versions
        }
    }

    func handleOpenFilterIntent(intent: INIntent) {
        if intent is SJOpenFilterIntent {
            let filterIntent = intent as! SJOpenFilterIntent
            guard let filterId = filterIntent.filterUuid, let filter = DataManager.sharedManager.findFilter(uuid: filterId) else { return }

            NavigationManager.sharedManager.navigateTo(NavigationManager.filterPageKey, data: [NavigationManager.filterUuidKey: filter.uuid])
        }
    }
}
