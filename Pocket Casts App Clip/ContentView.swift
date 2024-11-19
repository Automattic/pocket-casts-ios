import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct ContentView: View {
    var body: some View {
        VStack {
            NowPlayingPlayerItemViewControllerRepresentable()
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            guard
                let incomingURL = userActivity.webpageURL,
                let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
                let path = components.path,
                path != "/get",
                path != "/get/"
            else { return }

            // NOTE: This doesn't handle the redeem URL. See `AppDelegate.handleContinue(_ userActivity: NSUserActivity)` for this logic

            // Also pass any query params from the share URL to the server to allow support for episode position handling
            // Ex: ?t=123
            let query = components.query.map { "?\($0)" } ?? ""
            let sharePath = "\(path)\(query)"

            let importPath = "social/share/show\(sharePath)"

            PodcastManager.shared.importSharedItemFromUrl(importPath) { shareItem in
                guard let shareItem else {
                    print("Share Item")
                    return
                }

                guard let episodeUUID = shareItem.episodeHeader?.uuid else {
                    print("No episode found in share item")
                    return
                }

                guard let podcastUUID = shareItem.podcastHeader?.uuid else {
                    print("No podcast found in share item")
                    return
                }


                loadEpisode(episodeUuid: episodeUUID, podcastUuid: podcastUUID) {
                    guard let episode = DataManager.sharedManager.findEpisode(uuid: episodeUUID) else {
                        print("Could not find Episode")
                        return
                    }

                    print("Loaded episode: \(episode.title)")

                    PlaybackManager.shared.load(episode: episode, autoPlay: true, overrideUpNext: false)
                }
            }
        }
    }

    private func loadEpisode(episodeUuid: String, podcastUuid: String, timestamp: TimeInterval? = nil, completion: @escaping () -> Void) {
        if let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
            ServerPodcastManager.shared.updatePodcastIfRequired(podcast: podcast) { _ in
                completion()
            }

            return
        }

        ServerPodcastManager.shared.addFromUuid(podcastUuid: podcastUuid, subscribe: false, completion: { success in
            if success, let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
                completion()
            } else {
                DispatchQueue.main.async {
                    //TODO: Show alert
//                    self.hideProgressDialog()
//                    SJUIUtils.showAlert(title: L10n.podcastShareErrorTitle, message: L10n.podcastShareErrorMsg, from: SceneHelper.rootViewController())
                }
            }
        })
    }
}

#Preview {
    ContentView()
}
