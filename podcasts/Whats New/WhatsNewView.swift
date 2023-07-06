import SwiftUI

struct WhatsNewView: View {
    @EnvironmentObject var theme: Theme

    let announcement: WhatsNew.Announcement

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .frame(height: 195)

                Spacer()
                Button {
                    NavigationManager.sharedManager.dismissPresentedViewController()
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
                    .padding(.bottom)
                Button("Enable it") { }
                    .buttonStyle(RoundedDarkButton(theme: theme))
            }
            .padding()
        }
        .frame(minWidth: 300, maxWidth: 340)
        .background(theme.primaryUi01)
        .cornerRadius(5)
        .padding()
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView(announcement: .init(version: 7.20, image: "", title: "Autoplay is here!", message: "If your Up Next queue is empty, Pocket Casts can autoplay episodes from the list you started playing it — either a specific podcast, a filter, downloaded episodes or your own files."))
            .environmentObject(Theme(previewTheme: .light))
    }
}
