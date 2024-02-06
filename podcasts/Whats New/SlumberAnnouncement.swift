import SwiftUI
import PocketCastsServer

struct SlumberAnnouncement: View {
    @EnvironmentObject var theme: Theme

    @State var announcement: WhatsNew.Announcement

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(L10n.cancel) {
                    dismiss()
                }
                .frame(minHeight: 44)

                Spacer()
            }
            .padding(.horizontal, 15)

            Spacer()

            announcement.header()

            Spacer()

            VStack(spacing: 10) {
                if announcement.displayTier != .none {
                    SubscriptionBadge(tier: announcement.displayTier,
                                      displayMode: .gradient,
                                      fontSize: 16)
                    .padding(.bottom, 5)
                }

                Text(announcement.title)
                    .font(style: .title, weight: .bold)
                    .foregroundStyle(theme.primaryText01)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)
                UnderlineLinkTextView(announcement.message)
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

                Button(announcement.buttonTitle) {
                    track(.whatsnewConfirmButtonTapped)

                    announcement.action()
                }
                .buttonStyle(RoundedButtonStyle(theme: theme))
                .padding(.top, 40)
                .padding(.bottom, 15)
            }
            .padding(.horizontal, 24)
        }
        .background(theme.primaryUi01)
        .onAppear {
            track(.whatsnewShown)
            Settings.lastWhatsNewShown = announcement.version
        }
        .onReceive(NotificationCenter.default.publisher(for: ServerNotifications.subscriptionStatusChanged), perform: { _ in
            // Re-render if the user purchases
            if let slumberAnnouncement = WhatsNew().announcements.first(where: { $0.version == "7.57" }) {
                announcement = slumberAnnouncement
            }
        })
    }

    private func dismiss(completion: (() -> Void)? = nil) {
        NavigationManager.sharedManager.dismissPresentedViewController {
            completion?()
            NotificationCenter.postOnMainThread(notification: .whatsNewDismissed)
        }
    }

    private func track(_ event: AnalyticsEvent) {
        Analytics.track(event, properties: ["version": "\(announcement.version)"])
    }
}

struct WhatsNewFullView_Previews: PreviewProvider {
    static var previews: some View {
        SlumberAnnouncement(announcement: Announcements().announcements.last!)
            .environmentObject(Theme(previewTheme: .light))
    }
}
