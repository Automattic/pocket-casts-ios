import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct CompletionRateStory: ShareableStory {
    var duration: TimeInterval = 5.seconds

    let identifier: String = "year_over_year"

    let subscriptionTier: SubscriptionTier

    var body: some View {
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                StoryLabelContainer(geometry: geometry) {
                    SubscriptionBadge(tier: subscriptionTier, displayMode: .gradient, foregroundColor: .black)
                    StoryLabel(L10n.eoyYearCompletionRateTitle("10%"), for: .title, geometry: geometry)
                    StoryLabel(L10n.eoyYearCompletionRateSubtitle(30, 15), for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                }
                .padding(.bottom, geometry.size.height * 0.06)

                Spacer()

                Text("heh")
            }
            .background(
                ZStack(alignment: .top) {
                    Color.black

                    PlusStoryGradient()
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
            StoryShareableText(L10n.eoyYearOverShareText)
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
        CompletionRateStory(subscriptionTier: .plus)
            .previewDisplayName("Went down")
    }
}
