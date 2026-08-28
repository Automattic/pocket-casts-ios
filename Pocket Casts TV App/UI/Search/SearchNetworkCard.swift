import Kingfisher
import PocketCastsServer
import SwiftUI

/// A network in the search results, drawn as a cover card the way podcast results are.
struct SearchNetworkCard: View {

    enum Layout {
        static let size = CGFloat(250)
        static let cornerRadius = CGFloat(12)
    }

    let network: NetworkSearchResult

    var size: CGFloat = Layout.size

    var body: some View {
        artwork
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
            .focusedCardDepth(cornerRadius: Layout.cornerRadius, style: .surface)
            .accessibilityElement()
            .accessibilityLabel(network.accessibilityLabel)
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = network.collectionImageURL {
            KFImage(url)
                .placeholder { _ in placeholder }
                .fade(duration: 0.25)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Color.pcBackgroundOverlay
    }
}

extension NetworkSearchResult {
    var collectionImageURL: URL? {
        collectionImage.flatMap { URL(string: $0) }
    }

    var accessibilityLabel: String {
        [title, description].compactMap { $0 }.joined(separator: ", ")
    }
}

#Preview {
    HStack(spacing: 48) {
        SearchNetworkCard(network: NetworkSearchResult(
            uuid: "c73d120f-c174-4324-b0a3-18f9b239a59d",
            title: "WNYC",
            description: "New York's flagship public radio station",
            collectionImage: "https://static.pocketcasts.com/share/images/c73d120f-c174-4324-b0a3-18f9b239a59d-author.png",
            podcastCount: 11
        ))
        SearchNetworkCard(network: NetworkSearchResult(
            uuid: "cdb75bc0-9f5a-4217-b1ca-f573821a7913",
            title: "Relay",
            description: "The Relay network of podcasts.",
            collectionImage: nil,
            podcastCount: 4
        ))
    }
}
