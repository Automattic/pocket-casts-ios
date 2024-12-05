import SwiftUI
import PocketCastsServer
import PocketCastsUtils

struct PaidStoryWallView2024: View {
    @StateObject private var model = PlusPricingInfoModel()

    let subscriptionTier: SubscriptionTier

    private let words = [
        "Wait",
        "Attendez",
        "Espera",
        "Aspettare",
        "Agarda"
    ].map { $0.uppercased() }

    private let separator = Image("playback-24-union")

    private let foregroundColor = Color.black
    private let backgroundColor = Color(hex: "#EFECAD")
    private let marqueeColor = Color(hex: "#F9BC48")

    let identifier = "plus_interstitial"

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                ZStack {
                    VStack(spacing: -20) {
                        let separatorPadding: Double = -4
                        MarqueeTextView(words: words, separator: separator, separatorPadding: separatorPadding, direction: .leading)
                        MarqueeTextView(words: words, separator: separator, separatorPadding: separatorPadding, direction: .trailing)
                    }
                    .minimumScaleFactor(0.9)
                    .foregroundStyle(marqueeColor)
                    .rotationEffect(.degrees(-15))
                    .frame(width: geometry.size.width + 200, height: geometry.size.width - 50)
                    .offset(x: -50)
                }
                .frame(width: geometry.size.width, height: geometry.size.width)

                VStack(alignment: .leading, spacing: 0) {
                    StoryFooter2024(title: L10n.playback2024PlusUpsellTitle, description: L10n.playback2024PlusUpsellDescription, subscriptionTier: .plus)
                    Button(L10n.playback2024PlusUpsellButtonTitle) {
                        guard let storiesViewController = FeatureFlag.newPlayerTransition.enabled ? SceneHelper.rootViewController() : SceneHelper.rootViewController()?.presentedViewController else {
                            return
                        }

                        NavigationManager.sharedManager.showUpsellView(from: storiesViewController, source: .endOfYear, flow: SyncManager.isUserLoggedIn() ? .endOfYearUpsell : .endOfYear)
                    }
                    .allowsHitTesting(true)
                    .buttonStyle(BasicButtonStyle(textColor: .black, backgroundColor: Color.clear, borderColor: .black))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
                }
            }
        }
        .foregroundStyle(foregroundColor)
        .background {
            backgroundColor
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            Analytics.track(.endOfYearUpsellShown)
            Analytics.track(.endOfYearStoryShown, story: identifier)
        }
    }
}

#Preview {
    PaidStoryWallView()
}
