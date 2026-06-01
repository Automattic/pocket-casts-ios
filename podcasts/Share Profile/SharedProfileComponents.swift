import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct SharedProfileSubscribeButton: View {
    enum Style {
        case inline
        case overlay
    }

    @EnvironmentObject var theme: Theme
    @State private var isSubscribed: Bool

    let podcastUuid: String
    let style: Style

    init(podcastUuid: String, style: Style = .inline) {
        self.podcastUuid = podcastUuid
        self.style = style
        _isSubscribed = State(initialValue: DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: false) != nil)
    }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSubscribed {
                    if let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid) {
                        PodcastManager.shared.unsubscribe(podcast: podcast)
                        isSubscribed = false
                    }
                } else {
                    ServerPodcastManager.shared.subscribe(to: podcastUuid, completion: nil)
                    isSubscribed = true
                    HapticsHelper.triggerSubscribedHaptic()
                }
            }
        } label: {
            Group {
                switch style {
                case .inline:
                    inlineLabel
                case .overlay:
                    overlayLabel
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(isSubscribed ?
            (FeatureFlag.useFollowNaming.enabled ? L10n.unfollow : L10n.subscribed) :
            (FeatureFlag.useFollowNaming.enabled ? L10n.follow : L10n.subscribe)
        )
        .onReceive(NotificationCenter.default.publisher(for: Constants.Notifications.podcastAdded)) { _ in
            refreshSubscriptionState()
        }
        .onReceive(NotificationCenter.default.publisher(for: Constants.Notifications.podcastDeleted)) { _ in
            refreshSubscriptionState()
        }
    }

    private func refreshSubscriptionState() {
        let subscribed = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: false) != nil
        if subscribed != isSubscribed {
            isSubscribed = subscribed
        }
    }

    private var inlineLabel: some View {
        ZStack {
            if isSubscribed {
                Image("discover_tick")
                    .foregroundColor(AppTheme.color(for: .support02, theme: theme))
            } else {
                Image("discover_add")
                    .foregroundColor(AppTheme.color(for: .primaryIcon02, theme: theme))
            }
        }
        .frame(width: 32, height: 32)
    }

    private var overlayLabel: some View {
        Image(isSubscribed ? "discover_subscribed_dark" : "discover_subscribe_dark")
            .foregroundColor(ThemeColor.contrast01(for: theme.activeTheme).color)
            .frame(width: 28, height: 28)
            .background(ThemeColor.veil(for: theme.activeTheme).color)
            .clipShape(Circle())
    }
}

struct EpisodePlayButton: View {
    @EnvironmentObject var theme: Theme

    private let size: CGFloat = 28
    private let strokeWidth: CGFloat = 2

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.color(for: .primaryIcon01, theme: theme), lineWidth: strokeWidth)

            PlayTriangle()
                .fill(AppTheme.color(for: .primaryIcon01, theme: theme))
                .frame(width: size * 0.36, height: size * 0.36)
                .offset(x: size * 0.03)
        }
        .frame(width: size, height: size)
    }
}

struct PlayTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint.zero)
            path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.closeSubpath()
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .applyButtonEffect(isPressed: configuration.isPressed, scaleEffectNumber: 0.8)
    }
}
