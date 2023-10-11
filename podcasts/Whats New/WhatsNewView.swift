import SwiftUI

struct WhatsNewView: View {
    @EnvironmentObject var theme: Theme

    let announcement: WhatsNew.Announcement

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                announcement.header()
            }
            VStack(spacing: 10) {
                if announcement.unlockTier != .none {
                    SubscriptionBadge(tier: announcement.unlockTier,
                                      displayMode: .gradient,
                                      fontSize: 16)
                    .padding(.bottom, 5)
                }

                Text(announcement.title)
                    .font(style: .title3, weight: .bold)
                    .foregroundStyle(theme.primaryText01)
                    .multilineTextAlignment(.center)
                Text(announcement.message)
                    .font(style: .subheadline)
                    .foregroundStyle(theme.primaryText02)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                Button(announcement.buttonTitle) {
                    track(.whatsnewConfirmButtonTapped)

                    announcement.action()

                    dismiss()
                }
                    .buttonStyle(RoundedButtonStyle(theme: theme))
                Button(L10n.maybeLater) {
                    dismiss()
                    track(.whatsnewDismissed)
                }
                .buttonStyle(SimpleTextButtonStyle(theme: theme, size: 16, textColor: .primaryInteractive01, style: .subheadline, weight: .medium))
                    .padding(.bottom, 5)
                    .padding(.top, -5)
            }
            .padding(.horizontal)
            .padding(.top)
        }
        .frame(minWidth: 300, maxWidth: 340)
        .background(theme.primaryUi01)
        .cornerRadius(5)
        .padding()
        .onAppear {
            track(.whatsnewShown)
            Settings.lastWhatsNewShown = announcement.version
        }
    }

    private func dismiss() {
        NavigationManager.sharedManager.dismissPresentedViewController()

        NotificationCenter.postOnMainThread(notification: .whatsNewDismissed)
    }

    private func track(_ event: AnalyticsEvent) {
        Analytics.track(event, properties: ["version": "\(announcement.version)"])
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView(announcement: Announcements().announcements.last!)
            .environmentObject(Theme(previewTheme: .light))
    }
}
