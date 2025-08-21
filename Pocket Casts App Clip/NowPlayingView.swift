import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import StoreKit
import PocketCastsUtils
import UserNotifications

struct NowPlayingView: View {

    enum ScreenState: Int {
        case loading
        case ready
        case failed
    }

    @State var presentAppStoreOverlay: Bool = false
    @State var state: ScreenState = .loading

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack { Spacer() }
            switch state {
            case .loading:
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(UIColor.label.color)
            case .ready:
                NowPlayingPlayerItemViewControllerRepresentable()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                            presentAppStoreOverlay = true
                        }
                        scheduleNotification()
                    }
            case .failed:
                errorView
                    .onAppear {
                        presentAppStoreOverlay = true
                    }
            }
            Spacer()
        }
        .background(state != .ready ? UIColor.systemBackground.color : PlayerColorHelper.playerBackgroundColor01().color)
        .appStoreOverlay(isPresented: $presentAppStoreOverlay, configuration: {
            SKOverlay.AppClipConfiguration(position: .bottom)
        })
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            handle(userActivity: userActivity)
        }
    }

    var errorView: some View {
        VStack(spacing: 0) {
            Image("ac-yield")
                .renderingMode(.template)
                .foregroundStyle(UIColor.systemGray.color)
                .frame(width: 40.0, height: 40.0)
                .padding(.top, 240.0)
                .padding(.bottom, 16.0)
            Text(L10n.appClipPlacholderTitle)
                .foregroundStyle(UIColor.label.color)
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.bottom, 16.0)
            Text(L10n.appClipPlacholderMessage)
                .foregroundStyle(UIColor.secondaryLabel.color)
                .font(.system(size: 15, weight: .regular))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func handle(userActivity: NSUserActivity) {
        guard
            let incomingURL = userActivity.webpageURL,
            let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
            let path = components.path,
            path != "/get",
            path != "/get/"
        else {
            showErrorMessage(userActivity: userActivity)
            return
        }

        // NOTE: This doesn't handle the redeem URL. See `AppDelegate.handleContinue(_ userActivity: NSUserActivity)` for this logic

        // Also pass any query params from the share URL to the server to allow support for episode position handling
        // Ex: ?t=123
        let query = components.query.map { "?\($0)" } ?? ""
        let sharePath = "\(path)\(query)"

        let importPath = "social/share/show\(sharePath)"

        PodcastManager.shared.importSharedItemFromUrl(importPath) { shareItem in
            guard let shareItem else {
                FileLog.shared.addMessage("App Clip: Missing Share Item")
                showErrorMessage(userActivity: userActivity)
                return
            }

            guard let podcastUUID = shareItem.podcastHeader?.uuid else {
                FileLog.shared.addMessage("App Clip: No podcast found in share item")
                showErrorMessage(userActivity: userActivity)
                return
            }

            let episodeUUID = shareItem.episodeHeader?.uuid

            loadPodcast(podcastUuid: podcastUUID) { podcast in
                let episode: Episode?
                if let episodeUUID {
                    episode = DataManager.sharedManager.findEpisode(uuid: episodeUUID)
                } else {
                    episode = DataManager.sharedManager.findLatestEpisode(podcast: podcast)
                }

                guard let episode else {
                    FileLog.shared.addMessage("App Clip: Could not find Episode")
                    showErrorMessage(userActivity: userActivity)
                    return
                }

                FileLog.shared.addMessage("App Clip: Loaded episode: \(episode.title ?? "unknown")")
                state = .ready
                PlaybackManager.shared.load(episode: episode, autoPlay: true, overrideUpNext: false)
                Analytics.track(.playbackPlay, source: AnalyticsSource.handleUserActivity, properties: ["url": incomingURL.absoluteString, "podcast": podcastUUID, "episode": episode.uuid])
            }
        }
    }

    private func showErrorMessage(userActivity: NSUserActivity) {
        userActivity.invalidate()
        state = .failed
    }

    private func loadPodcast(podcastUuid: String, timestamp: TimeInterval? = nil, completion: @escaping (Podcast) -> Void) {
        if let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
            ServerPodcastManager.shared.updatePodcastIfRequired(podcast: podcast) { _ in
                DispatchQueue.main.async {
                    completion(podcast)
                }
            }
            return
        }

        ServerPodcastManager.shared.addFromUuid(podcastUuid: podcastUuid, subscribe: false, completion: { success in
            if success, let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
                DispatchQueue.main.async {
                    completion(podcast)
                }
            } else {
                DispatchQueue.main.async {
                    state = .failed
                }
            }
        })
    }

    private func scheduleNotification() {
        let notificationCenter = UNUserNotificationCenter.current()
        Task {
            do {
                let settings = await notificationCenter.notificationSettings()
                let granted = settings.authorizationStatus == .ephemeral
                guard granted else {
                    let settings = await notificationCenter.notificationSettings()
                    FileLog.shared.addMessage("App Clip: Notification status: \(settings.authorizationStatus)")
                    return
                }
                let content = UNMutableNotificationContent()
                content.title = L10n.notificationsAppClipTitle
                content.body = L10n.notificationsAppClipBody
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4.hours, repeats: false)
                let request = UNNotificationRequest(identifier: AppClipNotification.appStoreNotificationID, content: content, trigger: trigger)
                try await notificationCenter.add(request)
            } catch {
                FileLog.shared.addMessage("App Clip: Notification Sending Error - \(error)")
            }
        }
    }
}

#Preview {
    NowPlayingView()
}
