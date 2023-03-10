import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct SubscribeButtonView: View {
    @ObservedObject var model: SubscribeButtonModel

    init(podcastUuid: String) {
        self.model = SubscribeButtonModel(podcastUuid: podcastUuid)
    }

    var body: some View {
        Button(action: {
            if !model.isSubscribed {
                withAnimation {
                    model.isSubscribed = true
                    model.subscribe()
                }
            }
        }) {
            if model.isSubscribed {
                Image("discover_subscribed_dark")
            } else {
                Image("discover_subscribe_dark")
            }
        }
        .buttonStyle(SubscribeButtonStyle())
        .onAppear {
            model.checkSubscriptionStatus()
        }
    }
}

class SubscribeButtonModel: ObservableObject {
    @Published var isSubscribed: Bool

    let podcastUuid: String

    init(podcastUuid: String) {
        self.podcastUuid = podcastUuid
        isSubscribed = DataManager.sharedManager.findPodcast(uuid: podcastUuid) != nil
    }

    func subscribe() {
        ServerPodcastManager.shared.addFromUuid(podcastUuid: podcastUuid, subscribe: true, completion: nil)
        Analytics.track(.podcastSubscribed, properties: ["source": AnalyticsSource.discover, "uuid": podcastUuid])
    }

    func checkSubscriptionStatus() {
        isSubscribed = DataManager.sharedManager.findPodcast(uuid: podcastUuid) != nil
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
