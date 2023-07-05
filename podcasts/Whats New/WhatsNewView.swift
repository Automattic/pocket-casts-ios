import SwiftUI

struct WhatsNewView: View {
    @EnvironmentObject var theme: Theme

    let announcement: WhatsNewAnnouncement

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .top) {
                Rectangle()
                    .frame(height: 195)

                HStack {
                    Spacer()
                    Button {
                        NavigationManager.sharedManager.dismissPresentedViewController()
                    } label: {
                        ZStack {
                            Image("close")
                                .foregroundColor(.white)
                        }
                        .frame(width: 44, height: 44)
                    }
                }
            }
            Text(announcement.title)
                .font(style: .title3, weight: .bold)
                .padding(.horizontal)
                .padding(.top)
                .foregroundColor(theme.primaryText01)
            Text(announcement.message)
                .font(style: .subheadline)
                .foregroundColor(theme.secondaryText02)
                .padding(.horizontal)
                .padding(.bottom)
            Button("Enable it") {}
                .buttonStyle(RoundedDarkButton(theme: theme))
                .padding(.horizontal)
                .padding(.bottom)
        }
        .frame(width: 340)
        .background(.white)
        .cornerRadius(5)
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView(announcement: .init(version: 7.20, image: "", title: "Autoplay is here!", message: "If your Up Next queue is empty, Pocket Casts can autoplay episodes from the list you started playing it — either a specific podcast, a filter, downloaded episodes or your own files."))
            .environmentObject(Theme(previewTheme: .light))
    }
}
