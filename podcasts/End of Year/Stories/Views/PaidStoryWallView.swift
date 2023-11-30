import SwiftUI
import PocketCastsServer

struct PaidStoryWallView: View {
    @StateObject private var model = PlusPricingInfoModel()

    var body: some View {
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                StoryLabelContainer(geometry: geometry) {
                    SubscriptionBadge(tier: .plus, displayMode: .gradient, foregroundColor: .black)
                    StoryLabel(L10n.eoyTheresMore, for: .title, geometry: geometry)
                    StoryLabel(L10n.eoySubscribeToPlus, for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                }
                .padding(.bottom, geometry.size.height * 0.06)

                Button(model.pricingInfo.hasFreeTrial ? L10n.eoyStartYourFreeTrial : L10n.upgradeToPlan(L10n.pocketCastsPlusShort)) {
                    guard let storiesViewController = SceneHelper.rootViewController() else {
                        return
                    }

                    NavigationManager.sharedManager.showUpsellView(from: storiesViewController, source: .endOfYear, flow: SyncManager.isUserLoggedIn() ? .endOfYearUpsell : .endOfYear)

                }
                .buttonStyle(StoriesButtonStyle(color: .black, icon: nil))
            }
        }
        .background(
            Rectangle()
                .fill(.clear)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        )
        .onAppear {
            Analytics.track(.endOfYearUpsellShown)
        }
    }
}

private struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

#Preview {
    PaidStoryWallView()
}
