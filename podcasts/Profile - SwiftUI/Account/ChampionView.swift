import SwiftUI
import PocketCastsServer

struct ChampionView: View {
    @EnvironmentObject var theme: Theme

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 16) {
            Image("crown")
                .renderingMode(.template)
                .tint(theme.primaryUi05Selected)
            Text("You’re a true champion of Pocket Casts!")
                .font(style: .title, weight: .semibold)
                .multilineTextAlignment(.center)
            Text("Thanks for being with us since the beginning! If you enjoy using our app, we’d love to hear your feedback.")
                .font(style: .callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.primaryUi05Selected)
            Button(action: {
                openURL(URL(string: ServerConstants.Urls.appStoreReview)!)
            }, label: {
                Text("Rate Pocket Casts")
            })
            .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive02, backgroundColor: theme.primaryText01))
        }
        .padding()
        .applyDefaultThemeOptions()
    }
}

struct ChampionView_Previews: PreviewProvider {
    static var previews: some View {
        ChampionView()
            .previewWithAllThemes()
    }
}
