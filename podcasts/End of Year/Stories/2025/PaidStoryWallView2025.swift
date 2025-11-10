import SwiftUI
import AVKit
import PocketCastsServer
import PocketCastsUtils

struct PaidStoryWallView2025: View {
    let identifier = "plus_interstitial"

    @StateObject private var model = PlusPricingInfoModel()

    let subscriptionTier: SubscriptionTier

    private let foregroundColor = Color.black

    private let backgroundColor = Color(hex: "#9CB6CF")// Using video background color instead of the one defined in Figma: Color(hex: "#96BCD1")

    private let player: AVQueuePlayer
    private let looper: AVPlayerLooper?

    private let videoAspectRatio = CGFloat(1.777)

    init(subscriptionTier: SubscriptionTier) {
        self.subscriptionTier = subscriptionTier
        self.player = AVQueuePlayer()
        if let videoURL = Bundle.main.url(forResource: "playback_2025_plus", withExtension: "mp4") {
            let item = AVPlayerItem(url: videoURL)
            self.looper = AVPlayerLooper(player: player, templateItem: item)
        } else {
            self.looper = nil
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(width: geometry.size.width)
                    .aspectRatio(contentMode: .fill)
                    .background() {
                        GeometryReader { geometry in
                            HStack {
                                Spacer()
                                VideoPlayer(player: player)
                                    .frame(width: (geometry.size.height / videoAspectRatio).rounded(),
                                           height: geometry.size.height)
                                    .allowsHitTesting(false)
                                    .clipped()
                                Spacer()
                            }
                        }
                    }
                StoryHeader2025(title: L10n.playback2025PlusUpsellTitle, description: L10n.playback2025PlusUpsellDescription, subscriptionTier: .plus, topPadding: 0)
                Button(L10n.playback2025PlusUpsellButtonTitle) {
                    guard let storiesViewController = SceneHelper.rootViewController() else {
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
        .foregroundStyle(foregroundColor)
        .background {
            backgroundColor
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            player.play()
            Analytics.track(.endOfYearUpsellShown, properties: ["year": "2025"])
            Analytics.track(.endOfYearStoryShown, story: identifier)
        }
    }
}

#Preview {
    PaidStoryWallView2025(subscriptionTier: .plus)
}
