import SwiftUI

struct WhatsNewView: View {
    @EnvironmentObject var theme: Theme

    let announcement: WhatsNew.Announcement

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    LinearGradient(colors: [.init(hex: "03A9F4"), .init(hex: "50D0F1")], startPoint: .top, endPoint: .bottom)
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
                    dismiss()

                    announcement.action()
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
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView(announcement: .init(version: 7.20, image: "", title: "Autoplay is here!", message: "If your Up Next queue is empty, Pocket Casts can autoplay episodes from the list you started playing it — either a specific podcast, a filter, downloaded episodes or your own files.", buttonTitle: "Enable it", action: {}))
            .environmentObject(Theme(previewTheme: .light))
    }
}
