import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

struct PodcastSubscribeButton: View {
    let podcast: DiscoverPodcast

    @State private var isSubscribed: Bool = false
    @State private var scale: CGFloat = 1.0

    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                scale = 0.7
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                toggleSubscription()
                withAnimation(.easeInOut(duration: 0.2)) {
                    scale = 1.0
                }
            }
        }) {
            Color.clear
        }
        .overlay(alignment: .bottomTrailing) {
            Image(isSubscribed ? "discover_subscribed_dark" : "discover_subscribe_dark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ThemeColor.contrast01(for: theme.activeTheme).color)
                .frame(width: 28, height: 28)
                .background(ThemeColor.veil(for: theme.activeTheme).color)
                .clipShape(Circle())
                .scaleEffect(scale)
                .offset(x: -4, y: -4)
        }
        .accessibilityLabel(isSubscribed ?
            (FeatureFlag.useFollowNaming.enabled ? L10n.unfollow : L10n.subscribed) :
            (FeatureFlag.useFollowNaming.enabled ? L10n.follow : L10n.subscribe)
        )
    }

    private func toggleSubscription() {
        if isSubscribed {
            unsubscribe()
        } else {
            subscribe()
        }
    }

    private func subscribe() {
        guard let uuid = podcast.uuid else { return }

        isSubscribed = true

        if podcast.iTunesOnly() {
            if let iTunesId = podcast.iTunesId, let iTunesIdInt = Int(iTunesId) {
                ServerPodcastManager.shared.subscribeFromItunesId(iTunesIdInt, completion: nil)
            }
        } else {
            ServerPodcastManager.shared.subscribe(to: uuid, completion: nil)
        }

        HapticsHelper.triggerSubscribedHaptic()

        let analyticsUuid = podcast.uuid ?? podcast.iTunesId ?? "unknown"
        Analytics.track(.podcastSubscribed, properties: ["source": searchAnalyticsHelper.source, "uuid": analyticsUuid])
    }

    private func unsubscribe() {
        guard let uuid = podcast.uuid else { return }

        guard let podcast = DataManager.sharedManager.findPodcast(uuid: uuid) else { return }

        isSubscribed = false

        PodcastManager.shared.unsubscribe(podcast: podcast)

        Analytics.track(.podcastUnsubscribed, properties: ["source": searchAnalyticsHelper.source, "uuid": podcast.uuid])
    }
}
