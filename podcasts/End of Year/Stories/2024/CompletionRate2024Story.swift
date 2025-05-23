import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct CompletionRate2024Story: ShareableStory {
    @Environment(\.animated) var animated: Bool

    let plusOnly = true

    let subscriptionTier: SubscriptionTier

    let startedAndCompleted: EpisodesStartedAndCompleted

    let identifier: String = "completion_rate"

    private let foregroundColor = Color.black
    private let backgroundColor = Color(hex: "#E0EFAD")

    @ObservedObject private var animationViewModel = PlayPauseAnimationViewModel(duration: 0.3, animation: Animation.linear(duration:))

    @State private var chartOpacity: Double = 1

    @ObservedObject private var animationChartViewModel = PlayPauseAnimationViewModel(duration: 0.8, animation: Animation.spring(_:))
    @State var scale: Double = 0

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                Spacer()
                chartView()
                .frame(height: geometry.size.height * 0.5)
                .opacity(chartOpacity)
                .modifier(animationViewModel.animate($chartOpacity, to: 1, after: 0.2))
                .modifier(animationChartViewModel.animate($scale, to: 1, after: 0.2))
                footerView()
                    .padding(.top, 24)
            }
        }
        .onAppear {
            if animated {
                animationViewModel.play()
                animationChartViewModel.play()
            }
        }
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
    }

    private var formattedPercentage: String {
        startedAndCompleted.percentage.formatted(.percent.precision(.fractionLength(0)))
    }

    @ViewBuilder func chartView() -> some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: -80) {
                VStack(spacing: 4) {
                    ForEach(0..<Int(geometry.size.height / 5), id: \.self) { _ in
                        Rectangle()
                            .frame(height: 1)
                    }
                }
                .frame(width: geometry.size.width / 2, height: geometry.size.height)
                .offset(y: 3) // Offset to ensure bottoms match
                .foregroundStyle(.black)
                if startedAndCompleted.percentage < 0.25 { // Switch layout if less than 25%
                    VStack(alignment: .trailing, spacing: 0) {
                        chartLabel()
                            .foregroundStyle(.black)
                        chartRectangle(size: geometry.size)
                            .foregroundStyle(.black)
                            .scaleEffect(x: 1, y: scale, anchor: .bottom)
                    }
                } else {
                    ZStack(alignment: .bottomTrailing) {
                        chartRectangle(size: geometry.size)
                            .scaleEffect(x: 1, y: scale, anchor: .bottom)
                        chartLabel()
                            .foregroundStyle(backgroundColor)
                            .padding(.trailing, 19)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder func chartLabel() -> some View {
        Text(formattedPercentage)
            .font(.custom("Humane-Medium", size: 96))
    }

    @ViewBuilder func chartRectangle(size: CGSize) -> some View {
        Rectangle()
            .frame(width: size.width / 2, height: size.height * startedAndCompleted.percentage)
    }

    @ViewBuilder func footerView() -> some View {
        StoryFooter2024(title: L10n.eoyYearCompletionRateTitle(formattedPercentage),
                        description: L10n.playback2024CompletionRateDescription(startedAndCompleted.started, startedAndCompleted.completed),
                        subscriptionTier: subscriptionTier)
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: identifier)
    }

    func onPause() {
        animationViewModel.pause()
        animationChartViewModel.pause()
    }

    func onResume() {
        animationViewModel.play()
        animationChartViewModel.play()
    }

    func sharingAssets() -> [Any] {
        [
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyYearCompletionRateShareText("2024"), year: .y2024)
        ]
    }
}

struct CompletionRateStory2024_Previews: PreviewProvider {
    static var previews: some View {
        CompletionRate2024Story(subscriptionTier: .plus, startedAndCompleted: .init(started: 100, completed: 10))
            .previewDisplayName("10%")

        CompletionRate2024Story(subscriptionTier: .plus, startedAndCompleted: .init(started: 100, completed: 25))
            .previewDisplayName("21%")

        CompletionRate2024Story(subscriptionTier: .plus, startedAndCompleted: .init(started: 100, completed: 70))
            .previewDisplayName("70%")

        CompletionRate2024Story(subscriptionTier: .plus, startedAndCompleted: .init(started: 100, completed: 100))
            .previewDisplayName("100%")
    }
}
