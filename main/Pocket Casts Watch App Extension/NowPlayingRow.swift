import SwiftUI

struct NowPlayingRow: View {
    @Binding var isPlaying: Bool
    @Binding var podcastName: String?

    var body: some View {
        NavigationLink(destination: NowPlayingContainerView()) {
            HStack {
                NowPlayingImage(isPlaying: $isPlaying)
                    .frame(width: 26, height: 26)
                VStack(alignment: .leading) {
                    Text(L10n.nowPlaying)
                    Text(podcastName ?? "")
                        .foregroundColor(.subheadlineText)
                }
                .font(.dynamic(size: 13))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(-4)
    }
}

struct NowPlayingRow_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingRow(isPlaying: .constant(false),
                      podcastName: .constant("WP Briefing"))
    }
}
