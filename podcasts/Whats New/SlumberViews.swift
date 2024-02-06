import SwiftUI
import SafariServices
import PocketCastsServer

struct SlumberWhatsNewHeader: View {
    @State var distance: CGFloat = 0

    var body: some View {
        HStack {
            Group {
                PodcastCover(podcastUuid: "82e37e80-755d-0138-eddc-0acc26574db2")
                    .offset(y: distance)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: distance)
                PodcastCover(podcastUuid: "9478cc80-7c42-0138-edfe-0acc26574db2")
                    .offset(y: distance)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(0.4), value: distance)
                PodcastCover(podcastUuid: "37082d70-e945-0137-b6eb-0acc26574db2")
                    .offset(y: distance)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(0.8), value: distance)
                PodcastCover(podcastUuid: "62200ab0-b7ec-0139-f606-0acc26574db2")
                    .offset(y: distance)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(1.2), value: distance)

            }
                .frame(width: 120, height: 120)
        }
        .onAppear {
            distance = 30
        }
            .environment(\.renderForSharing, false)
    }
}

struct SlumberCustomBody: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject private var viewModel = SlumberAnnouncementViewModel()

    var body: some View {
        Text(L10n.announcementSlumberTitle)
            .font(style: .title, weight: .bold)
            .foregroundStyle(theme.primaryText01)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 10)
        UnderlineLinkTextView(viewModel.message)
            .font(style: .body)
            .foregroundStyle(theme.primaryText01)
            .multilineTextAlignment(.center)
            .padding(.bottom)
            .fixedSize(horizontal: false, vertical: true)
            .onTapGesture {
                guard SubscriptionHelper.hasActiveSubscription() else {
                    return
                }

                UIPasteboard.general.string = Settings.slumberPromoCode
                Toast.show(L10n.announcementSlumberCodeCopied)
            }

        Button(viewModel.buttonTitle) {
            Analytics.track(.whatsnewConfirmButtonTapped)

            viewModel.showRedeemOrUpgrade()
        }
        .buttonStyle(RoundedButtonStyle(theme: theme))
        .padding(.top, 40)
        .padding(.bottom, 15)
        .onReceive(NotificationCenter.default.publisher(for: ServerNotifications.subscriptionStatusChanged), perform: { _ in
            viewModel.update()
        })
    }
}

class SlumberAnnouncementViewModel: ObservableObject {
    private lazy var upgradeOrRedeemViewModel = SlumberUpgradeRedeemViewModel()

    @Published var buttonTitle: String = ""

    @Published var message: String = ""

    init() {
        setUpCopies()
    }

    private func setUpCopies() {
        buttonTitle = SubscriptionHelper.hasActiveSubscription() ? L10n.announcementSlumberRedeem : L10n.plusSubscribeTo

        message = (SubscriptionHelper.hasActiveSubscription() ? L10n.announcementSlumberPlusDescription("**\(Settings.slumberPromoCode ?? "")**") : L10n.announcementSlumberNonPlusDescription).replacingOccurrences(of: L10n.announcementSlumberPlusDescriptionLearnMore, with: "[\(L10n.announcementSlumberPlusDescriptionLearnMore)](https://slumberstudios.com)")
    }

    func update() {
        setUpCopies()
    }

    func showRedeemOrUpgrade() {
        upgradeOrRedeemViewModel.showRedeemOrUpgrade()
    }
}

class SlumberUpgradeRedeemViewModel: PlusAccountPromptViewModel {
    let feature: PaidFeature = .slumber
    let upgradeSource: String = "slumber"

    var upgradeLabel: String {
        return L10n.plusSubscribeTo
    }

    func showRedeemOrUpgrade() {
        SubscriptionHelper.hasActiveSubscription() ? showRedeem() : upgradeTapped()
    }

    private func showRedeem() {
        guard let parentController = SceneHelper.rootViewController(), let url = URL(string: "https://slumberstudios.com/pocketcasts/") else { return }

        let safariController = SFSafariViewController(with: url)
        safariController.modalPresentationStyle = .formSheet
        parentController.present(safariController, animated: true)
    }

    override func showModal(for product: PlusPricingInfoModel.PlusProductPricingInfo? = nil) {
        guard let parentController = SceneHelper.rootViewController() else { return }

        feature.presentUpgradeController(from: parentController, source: upgradeSource)
    }
}

#Preview {
    SlumberWhatsNewHeader()
}
