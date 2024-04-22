import SwiftUI
import PocketCastsDataModel

struct ShareInfo {
    let podcast: Podcast
    let episode: Episode?
}

struct SharingView: View {

    let shareInfo: ShareInfo

    var body: some View {
        VStack {
            title
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color.white)
        .background(Color(hex: "2E0102"))
    }

    @ViewBuilder var title: some View {
        VStack {
            Text("Share episode")
                .font(.headline)
            Text("Choose a format and a platform to share to")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SharingView(shareInfo: ShareInfo(podcast: Podcast.previewPodcast(), episode: nil))
}
