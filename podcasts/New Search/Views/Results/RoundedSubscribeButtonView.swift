import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct RoundedSubscribeButtonView: View {
    @ObservedObject var model: SubscribeButtonModel

    init(podcastUuid: String, source: AnalyticsSource) {
        self.model = SubscribeButtonModel(podcastUuid: podcastUuid, source: source)
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
        .buttonStyle(RoundedSubscribeButtonStyle())
        .onAppear {
            model.checkSubscriptionStatus()
        }
    }
}

struct SubscribeButtonView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var model: SubscribeButtonModel

    init(podcastUuid: String, source: AnalyticsSource) {
        self.model = SubscribeButtonModel(podcastUuid: podcastUuid, source: source)
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
            .frame(width: 48, height: 48)
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

    init(podcastUuid: String, source: AnalyticsSource) {
        self.podcastUuid = podcastUuid
        self.source = source
        isSubscribed = DataManager.sharedManager.findPodcast(uuid: podcastUuid) != nil
    }

    func subscribe() {
        ServerPodcastManager.shared.addFromUuid(podcastUuid: podcastUuid, subscribe: true, completion: nil)
        Analytics.track(.podcastSubscribed, properties: ["source": source, "uuid": podcastUuid])
    }

    func checkSubscriptionStatus() {
        isSubscribed = DataManager.sharedManager.findPodcast(uuid: podcastUuid) != nil
    }
}

private struct RoundedSubscribeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .background(ThemeColor.veil().color)
        .foregroundColor(ThemeColor.contrast01().color)
        .cornerRadius(30)
        .padding([.trailing, .bottom], 6)
        .applyButtonEffect(isPressed: configuration.isPressed, scaleEffectNumber: 0.8)
    }
}

private struct SubscribeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .applyButtonEffect(isPressed: configuration.isPressed, scaleEffectNumber: 0.8)
    }
}
