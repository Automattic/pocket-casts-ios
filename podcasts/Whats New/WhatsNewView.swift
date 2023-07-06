import SwiftUI

struct WhatsNewView: View {
    @EnvironmentObject var theme: Theme

    let announcement: WhatsNew.Announcement

    @State private var scale = 1.0

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    announcement.header()
                }
                .frame(height: 195)

                Spacer()
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Image("close")
                            .foregroundStyle(.white)
                    }
                    .frame(width: 44, height: 44)
                }
            }
            VStack(spacing: 10) {
                Text(announcement.title)
                    .font(style: .title3, weight: .bold)
                    .foregroundStyle(theme.primaryText01)
                Text(announcement.message)
                    .font(style: .subheadline)
                    .foregroundStyle(theme.secondaryText02)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                Button(announcement.buttonTitle) {
                    announcement.action()

                    dismiss()
                }
                    .buttonStyle(RoundedButtonStyle(theme: theme))
                Button(L10n.maybeLater) {
                    dismiss()
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
    }

    private func dismiss() {
        NavigationManager.sharedManager.dismissPresentedViewController()

        NotificationCenter.postOnMainThread(notification: .whatsNewDismissed)
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView(announcement: Announcements().announcements.last!)
            .environmentObject(Theme(previewTheme: .light))
    }
}
