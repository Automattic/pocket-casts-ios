import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct SubscribeButtonView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var model: SubscribeButtonModel

    init(podcastUuid: String, source: AnalyticsSource, onSubscribe: (() -> Void)? = nil) {
        self.model = SubscribeButtonModel(podcastUuid: podcastUuid, source: source, subscribeBlock: onSubscribe)
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
            ZStack(alignment: .center) {
                if model.isSubscribed {
                    Image("discover_tick")
                        .foregroundColor(AppTheme.color(for: .support02, theme: theme))
                } else {
                    Image("discover_add")
                        .foregroundColor(AppTheme.color(for: .primaryIcon02, theme: theme))
                }
            }
            .frame(width: 32, height: 32)
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
    let source: AnalyticsSource

    let subscribeBlock: (() -> Void)?

    init(podcastUuid: String, source: AnalyticsSource, subscribeBlock: (() -> Void)?) {
        self.podcastUuid = podcastUuid
        self.source = source
        self.subscribeBlock = subscribeBlock
        isSubscribed = DataManager.sharedManager.findPodcast(uuid: podcastUuid) != nil
    }

    func subscribe() {
        ServerPodcastManager.shared.subscribe(to: podcastUuid, completion: nil)
        Analytics.track(.podcastSubscribed, properties: ["source": source, "uuid": podcastUuid])
        subscribeBlock?()
    }

    func checkSubscriptionStatus() {
        isSubscribed = DataManager.sharedManager.findPodcast(uuid: podcastUuid) != nil
    }
}

private struct SubscribeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .applyButtonEffect(isPressed: configuration.isPressed, scaleEffectNumber: 0.8)
    }
}
