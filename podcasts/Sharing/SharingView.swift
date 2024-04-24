import SwiftUI
import PocketCastsDataModel

struct ShareInfo {
    let podcast: Podcast
    let episode: Episode?
}

struct SharingView: View {

    private enum Constants {
        static let descriptionMaxWidth: CGFloat = 200
    }

    let shareInfo: ShareInfo

    var body: some View {
        VStack {
            title
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color.white)
    }

    @ViewBuilder var title: some View {
        VStack {
            Text(shareInfo.episode != nil ? "Share episode" : "Share podcast")
                .font(.headline)
            Text("Choose a format and a platform to share to")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: Constants.descriptionMaxWidth)
        }
    }
}

#Preview {
    SharingView(shareInfo: ShareInfo(podcast: Podcast.previewPodcast(), episode: nil))
}
