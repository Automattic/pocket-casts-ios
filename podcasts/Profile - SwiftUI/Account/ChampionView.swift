import SwiftUI
import PocketCastsServer

struct ChampionView: View {
    @EnvironmentObject var theme: Theme

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 16) {
            Image("crown")
            Text(L10n.championTitle)
                .font(style: .title, weight: .semibold)
                .multilineTextAlignment(.center)
            Text(L10n.championDescription)
                .font(style: .callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.primaryUi05Selected)
            Button(action: {
                openURL(URL(string: ServerConstants.Urls.appStoreReview)!)
            }, label: {
                Text(L10n.ratePocketCasts)
            })
            .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive02, backgroundColor: theme.primaryInteractive01))
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
