import PocketCastsServer
import SwiftUI

/// A network in the search results: round artwork beside its name and description.
struct NetworkSearchResultCell: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var networkNavigator: SearchNetworkNavigator

    let network: NetworkSearchResult

    let cellStyle: ListCellButtonStyle

    @ScaledMetric(relativeTo: .subheadline) private var artworkSize = 56

    var body: some View {
        Button(action: open) {
            rowContent
        }
        .buttonStyle(cellStyle)
        .listRowInsets(EdgeInsets())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private func open() {
        searchAnalyticsHelper.trackResultTapped(network)
        networkNavigator.show(network)
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            NetworkArtworkView(url: network.collectionImageURL, size: artworkSize)
                .clipShape(.circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(network.title)
                    .font(style: .subheadline, weight: .medium)
                    .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                    .lineLimit(2)
                if let description = network.description, !description.isEmpty {
                    Text(description)
                        .font(style: .subheadline)
                        .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                        .lineLimit(2)
                }
            }
            .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }
}

extension NetworkSearchResult {
    var collectionImageURL: URL? {
        collectionImage.flatMap { URL(string: $0) }
    }
}

#if DEBUG

/// Networks as search returns them, for previews.
enum NetworkSearchPreviewData {
    static let networks = [
        NetworkSearchResult(
            uuid: "e07f76d0-0064-48d9-81a3-895de009f5c7",
            title: "The New York Times",
            description: "The best journalism and storytelling in one place.",
            collectionImage: "https://static.pocketcasts.com/share/images/e07f76d0-0064-48d9-81a3-895de009f5c7-author.svg",
            podcastCount: 8
        ),
        NetworkSearchResult(
            uuid: "c73d120f-c174-4324-b0a3-18f9b239a59d",
            title: "WNYC",
            description: "New York's flagship public radio station",
            collectionImage: "https://static.pocketcasts.com/share/images/c73d120f-c174-4324-b0a3-18f9b239a59d-author.png",
            podcastCount: 11
        ),
        NetworkSearchResult(
            uuid: "cdb75bc0-9f5a-4217-b1ca-f573821a7913",
            title: "Relay",
            description: "The Relay network of podcasts.",
            collectionImage: nil,
            podcastCount: 4
        )
    ]
}

#Preview("Network rows") {
    List(NetworkSearchPreviewData.networks, id: \.self) { network in
        NetworkSearchResultCell(network: network, cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi02))
            .listRowBackground(AppTheme.color(for: .primaryUi02, theme: Theme.sharedTheme))
    }
    .listStyle(.plain)
    .setupDefaultEnvironment()
    .environmentObject(SearchAnalyticsHelper(source: .discover))
    .environmentObject(SearchNetworkNavigator(source: .discover))
}

#endif
