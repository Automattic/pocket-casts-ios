import SwiftUI

struct EpisodeActionView: View {
    let iconName: String
    let title: String

    var body: some View {
        HStack {
            Image(iconName, bundle: Bundle.watchAssets)
            Text(title)
                .font(.dynamic(size: 16))
            Spacer()
        }
    }
}

struct EpisodeActionView_Previews: PreviewProvider {
    static var previews: some View {
        EpisodeActionView(iconName: "episode_download", title: L10n.download)
            .previewDevice(.largeWatch)
    }
}
