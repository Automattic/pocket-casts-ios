import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import Lottie

struct CompletionRate2025Story: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    let plusOnly = true

    let subscriptionTier: SubscriptionTier

    let startedAndCompleted: EpisodesStartedAndCompleted

    let identifier: String = "completion_rate"

    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background

    @State private var chartOpacity: Double = 1

    var body: some View {
        VStack(alignment: .center) {
            headerView
            Spacer()
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: backgroundColor.opacity(1.0), location: 0),
                            .init(color: backgroundColor.opacity(0.0), location: 1)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(height: 120)
        }
        .background {
            LottieView(animation: .named(animationId(for: startedAndCompleted.percentage)))
                .configure({ animationView in
                    animationView.contentMode = .scaleAspectFill
                })
                .playbackMode(renderForSharing ? .paused(at: .progress(1)) : .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                .scaledToFill()
                .ignoresSafeArea()
                .offset(y: UIScreen.isSmallScreen ? 60 : 0)
        }
        .ignoresSafeArea()
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
    }

    @ViewBuilder var headerView: some View {
        StoryHeader2025(
            title: L10n.playback2025CompletionRateTitle(formattedPercentage),
            description: L10n.playback2025CompletionRateMessage(startedAndCompleted.started, startedAndCompleted.completed),
            subscriptionTier: subscriptionTier
        )
    }

    private var formattedPercentage: String {
        startedAndCompleted.percentage.formatted(.percent.precision(.fractionLength(0)))
    }

    private func animationId(for value: Double) -> String {
        switch value {
        case 0...0.3:
            return "2025_completion_rate_20"
        case 0.3...0.5:
            return "2025_completion_rate_40"
        case 0.5...0.7:
            return "2025_completion_rate_60"
        case 0.7...0.9:
            return "2025_completion_rate_80"
        default:
            return "2025_completion_rate_100"
        }
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: identifier)
    }

    func sharingAssets() -> [Any] {
        [
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyYearCompletionRateShareText("2025"), year: .y2025)
        ]
    }
}

struct CompletionRateStory2025_Previews: PreviewProvider {
    static var previews: some View {
        CompletionRate2025Story(subscriptionTier: .plus, startedAndCompleted: .init(started: 100, completed: 10))
            .previewDisplayName("10%")

        CompletionRate2025Story(subscriptionTier: .plus, startedAndCompleted: .init(started: 100, completed: 37))
            .previewDisplayName("37%")

        CompletionRate2025Story(subscriptionTier: .plus, startedAndCompleted: .init(started: 100, completed: 64))
            .previewDisplayName("64%")

        CompletionRate2025Story(subscriptionTier: .plus, startedAndCompleted: .init(started: 100, completed: 85))
            .previewDisplayName("85%")

        CompletionRate2025Story(subscriptionTier: .plus, startedAndCompleted: .init(started: 100, completed: 100))
            .previewDisplayName("100%")
    }
}
