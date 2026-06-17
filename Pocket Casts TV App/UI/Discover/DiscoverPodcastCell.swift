import SwiftUI

struct DiscoverPodcastCell: View {

    fileprivate enum Layout {
        static let gridSize = CGFloat(250)
    }

    let podcastUuid: String
    let isSponsored: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            PodcastImage(uuid: podcastUuid, size: .page)
                .padding(.horizontal, isSponsored ? 36 : 0)
                .padding(.top, isSponsored ? 18 : 0)
            if isSponsored {
                Text(L10n.discoverSponsored)
                    .font(.caption2)
                    .foregroundColor(.pcTextSecondary)
                    .padding(.bottom, 14)
            }
        }
        .frame(width: Layout.gridSize, height: Layout.gridSize)
    }
}
