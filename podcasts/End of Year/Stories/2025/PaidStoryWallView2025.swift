import SwiftUI
import AVKit
import PocketCastsServer
import PocketCastsUtils

struct PaidStoryWallView2025: View {
    let identifier = "plus_interstitial"

    @StateObject private var model = PlusPricingInfoModel()

    let subscriptionTier: SubscriptionTier

    private let foregroundColor = Color.black

    private let backgroundColor = Color(hex: "#96BCD1")

    private let videoAspectRatio = CGFloat(1.37)

    init(subscriptionTier: SubscriptionTier) {
        self.subscriptionTier = subscriptionTier
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(width: geometry.size.width)
                    .background() {
                        GeometryReader { geometry in
                            HStack {
                                Spacer()
                                CustomVideoPlayerView(urlString: "playback_2025_plus")
                                    .frame(width: ((geometry.size.height - 48.0) / videoAspectRatio).rounded(),
                                           height: (geometry.size.height - 48.0))
                                    .allowsHitTesting(false)
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, UIScreen.isSmallScreen ? 80 : 110)
                    .allowsHitTesting(false)
                StoryHeader2025(title: L10n.playback2025PlusUpsellTitle, description: L10n.playback2025PlusUpsellDescription, subscriptionTier: .plus, topPadding: 0)
                Button(L10n.playback2025PlusUpsellButtonTitle) {
                    guard let storiesViewController = SceneHelper.rootViewController() else {
                        return
                    }

                    NavigationManager.sharedManager.showUpsellView(from: storiesViewController, source: .endOfYear, flow: SyncManager.isUserLoggedIn() ? .endOfYearUpsell : .endOfYear)
                }
                .buttonStyle(BasicButtonStyle(textColor: .black, backgroundColor: Color.clear, borderColor: .black))
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 4)
            }
        }
        .foregroundStyle(foregroundColor)
        .background {
            CustomVideoPlayerView(urlString: "playback_2025_plus_background", backgroundColor: backgroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            Analytics.track(.endOfYearUpsellShown, properties: ["year": "2025"])
            Analytics.track(.endOfYearStoryShown, story: identifier)
        }
    }
}

fileprivate struct CustomVideoPlayerView: UIViewControllerRepresentable {

    private let player: AVQueuePlayer
    private let looper: AVPlayerLooper?
    private let backgroundColor: Color

    init(urlString: String, backgroundColor: Color = .clear) {
        self.player = AVQueuePlayer()
        if let videoURL = Bundle.main.url(forResource: urlString, withExtension: "mp4") {
            let item = AVPlayerItem(url: videoURL)
            self.looper = AVPlayerLooper(player: player, templateItem: item)
            player.play()
        } else {
            self.looper = nil
        }
        self.backgroundColor = backgroundColor
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.view.backgroundColor = UIColor(backgroundColor)
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        // Handle updates if needed
    }
}


#Preview {
    PaidStoryWallView2025(subscriptionTier: .plus)
}
