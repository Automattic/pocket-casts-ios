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
                        .foregroundStyle(theme.primaryText02)
                        .tint(theme.primaryInteractive01)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 12) {
                    Button(announcement.buttonTitle) {
                        track(.whatsnewConfirmButtonTapped)

                        announcement.action()
                    }
                    .buttonStyle(RoundedButtonStyle(theme: theme))

                    if let footnote = announcement.footnote {
                        Text(footnote)
                            .font(style: .footnote)
                            .foregroundStyle(theme.primaryText02)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.bottom, 15)
                .padding(.horizontal, 24)
            }
        }
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .background(theme.primaryUi01)
        .onAppear {
            track(.whatsnewShown)
        }
        .onDisappear {
            NotificationCenter.postOnMainThread(notification: .whatsNewDismissed)
        }
    }

    private var closeButton: some View {
        Button {
            SceneHelper.rootViewController()?.dismiss(animated: true)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.secondaryIcon01)
                .frame(width: 30, height: 30)
                .background(theme.primaryUi05)
                .clipShape(Circle())
        }
        .accessibilityLabel(L10n.close)
        .padding(.top, 16)
        .padding(.trailing, 16)
    }

    @ViewBuilder
    private var subscriptionBadge: some View {
        if announcement.displayTier != .none {
            SubscriptionBadge(tier: announcement.displayTier,
                              displayMode: .plain,
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
