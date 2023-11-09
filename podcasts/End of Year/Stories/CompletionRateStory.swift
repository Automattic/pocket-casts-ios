import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct CompletionRateStory: ShareableStory {
    var duration: TimeInterval = 5.seconds

    let identifier: String = "completion_rate"

    let plusOnly = true

    let subscriptionTier: SubscriptionTier

    let startedAndCompleted: EpisodesStartedAndCompleted

    var percentageToDisplay: String {
        "\(Int(startedAndCompleted.percentage * 100))%"
    }

    var body: some View {
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                StoryLabelContainer(geometry: geometry) {
                    SubscriptionBadge(tier: subscriptionTier, displayMode: .gradient, foregroundColor: .black)
                    StoryLabel(L10n.eoyYearCompletionRateTitle(percentageToDisplay), for: .title, geometry: geometry)
                    StoryLabel(L10n.eoyYearCompletionRateSubtitle(startedAndCompleted.started, startedAndCompleted.completed), for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                }
                .padding(.bottom, geometry.size.height * 0.06)

                Spacer()

                VStack {
                    ZStack {
                        Circle()
                           .rotation(.degrees(-90))
                           .stroke(Color(hex: "292B2E"), style: StrokeStyle(lineWidth: geometry.size.height * 0.02))
                           .frame(width: geometry.size.height * 0.35, height: geometry.size.height * 0.35)

                        LinearGradient(
                        stops: [
                        Gradient.Stop(color: Color(red: 0.25, green: 0.11, blue: 0.92), location: 0.00),
                        Gradient.Stop(color: Color(red: 0.68, green: 0.89, blue: 0.86), location: 0.24),
                        Gradient.Stop(color: Color(red: 0.87, green: 0.91, blue: 0.53), location: 0.50),
                        Gradient.Stop(color: Color(red: 0.91, green: 0.35, blue: 0.26), location: 0.74),
                        Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.1), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: -0.65, y: 0.5),
                        endPoint: UnitPoint(x: 1.49, y: 0.5)
                        )
                        .frame(width: geometry.size.height * 0.4, height: geometry.size.height * 0.4)
                        .rotationEffect(.degrees(-90))
                        .mask(
                            Circle()
                               .rotation(.degrees(-90))
                               .trim(from: 1 - startedAndCompleted.percentage, to: 1.0)
                               .stroke(.red, style: StrokeStyle(lineWidth: geometry.size.height * 0.03))
                               .scaleEffect(.init(width: -1, height: 1))
                               .frame(width: geometry.size.height * 0.35, height: geometry.size.height * 0.35)
                        )

                        VStack(spacing: 0) {
                            Text(percentageToDisplay)
                            .font(.custom("DM Sans", size: geometry.size.height * 0.127).weight(.light))
                            .foregroundColor(Color(red: 0.98, green: 0.98, blue: 0.99))

                            Text(L10n.eoyYearCompletionRate)
                            .font(
                            Font.custom("DM Sans", size: geometry.size.height * 0.018)
                            .weight(.semibold)
                            )
                            .foregroundColor(Color(red: 0.56, green: 0.59, blue: 0.64))
                            .padding(.top, -geometry.size.height * 0.02)

                        }
                    }

                    Rectangle()
                        .opacity(0)
                        .frame(height: geometry.size.height * 0.15)
                }
            }
            .background(
                ZStack(alignment: .top) {
                    Color.black

                    StoryGradient(geometry: geometry, plus: true)
                    .offset(x: geometry.size.width * 0.6, y: -geometry.size.height * 0.22)
                    .clipped()
                }
                .ignoresSafeArea()
            )
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
            StoryShareableText(L10n.eoyYearCompletionRateShareText)
        ]
    }
}

private extension Double {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

struct CompletionRateStory_Previews: PreviewProvider {
    static var previews: some View {
        CompletionRateStory(subscriptionTier: .plus, startedAndCompleted: .init(started: 100, completed: 10))
            .previewDisplayName("10%")

        CompletionRateStory(subscriptionTier: .plus, startedAndCompleted: .init(started: 100, completed: 30))
            .previewDisplayName("30%")

        CompletionRateStory(subscriptionTier: .plus, startedAndCompleted: .init(started: 100, completed: 70))
            .previewDisplayName("70%")

        CompletionRateStory(subscriptionTier: .plus, startedAndCompleted: .init(started: 100, completed: 100))
            .previewDisplayName("100%")
    }
}
