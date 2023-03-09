import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct SubscribeButtonView: View {
    @State var isSubscribed = false

    var podcastUuid: String

    init(podcastUuid: String) {
        self.podcastUuid = podcastUuid
    }

    var body: some View {
        Button(action: {
            if !isSubscribed {
                withAnimation {
                    isSubscribed = true
                    subscribe()
                }
            }
        }) {
            if isSubscribed {
                Image("discover_subscribed_dark")
            } else {
                Image("discover_subscribe_dark")
            }
        }
        .buttonStyle(SubscribeButtonStyle())
        .onAppear {
            isSubscribed = DataManager.sharedManager.findPodcast(uuid: podcastUuid) != nil
        }
    }

    private func subscribe() {
        ServerPodcastManager.shared.addFromUuid(podcastUuid: podcastUuid, subscribe: true, completion: nil)
        Analytics.track(.podcastSubscribed, properties: ["source": AnalyticsSource.discover, "uuid": podcastUuid])
    }
}

private struct SubscribeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .background(ThemeColor.veil().color)
        .foregroundColor(ThemeColor.contrast01().color)
        .cornerRadius(30)
        .padding([.trailing, .bottom], 6)
        .applyButtonEffect(isPressed: configuration.isPressed, scaleEffectNumber: 0.8)
    }
}
