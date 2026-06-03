import SwiftUI
import PocketCastsServer

struct WhatsNewFullView: View {
    @EnvironmentObject var theme: Theme

    var announcement: WhatsNew.Announcement

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            announcement.header()

            if let customBody = announcement.customBody() {
                Spacer()

                VStack(spacing: 10) {
                    subscriptionBadge
                    customBody
                }
                .padding(.horizontal, 24)
            } else {
                VStack(spacing: 10) {
                    subscriptionBadge

                    Text(announcement.title)
                        .font(style: .title, weight: .bold)
                        .foregroundStyle(theme.primaryText01)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                    UnderlineLinkTextView(announcement.message)
                        .font(style: .body)
                        .foregroundStyle(theme.primaryText01)
                        .tint(theme.primaryInteractive01)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)

                Spacer()

                Button(announcement.buttonTitle) {
                    track(.whatsnewConfirmButtonTapped)

                    announcement.action()
                }
                .buttonStyle(RoundedButtonStyle(theme: theme))
                .padding(.bottom, 15)
                .padding(.horizontal, 24)
            }
        }
        .background(theme.primaryUi01)
        .onAppear {
            track(.whatsnewShown)
        }
        .onDisappear {
            NotificationCenter.postOnMainThread(notification: .whatsNewDismissed)
        }
    }

    @ViewBuilder
    private var subscriptionBadge: some View {
        if announcement.displayTier != .none {
            SubscriptionBadge(tier: announcement.displayTier,
                              displayMode: .gradient,
                              fontSize: 16)
            .padding(.bottom, 5)
        }
    }

    private func track(_ event: AnalyticsEvent) {
        Analytics.track(event, properties: ["version": "\(announcement.version)"])
    }
}

struct WhatsNewFullView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewFullView(announcement: Announcements().announcements.last!)
            .previewWithAllThemes()
    }
}
