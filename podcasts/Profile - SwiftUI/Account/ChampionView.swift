import SwiftUI

struct ChampionView: View {
    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(spacing: 16) {
            Image("crown")
            Text("You’re a true champion of Pocket Casts!")
                .font(style: .title, weight: .semibold)
                .multilineTextAlignment(.center)
            Text("Thanks for being with us since the beginning! If you enjoy using our app, we’d love to hear your feedback.")
                .font(style: .body)
                .multilineTextAlignment(.center)
            Button(action: {
                // action
            }, label: {
                Text("Rate Pocket Casts")
            })
            .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive02, backgroundColor: theme.primaryText01))
        }
    }
}

struct ChampionView_Previews: PreviewProvider {
    static var previews: some View {
        ChampionView()
            .previewWithAllThemes()
    }
}
