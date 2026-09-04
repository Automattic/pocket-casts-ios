import Kingfisher
import PocketCastsServer
import SwiftUI

/// The Discover row for a `lists_list` item: the networks it contains, side by side.
struct DiscoverNetworksListRowView: View {

    @ObservedObject var model: DiscoverNetworksListModel

    @EnvironmentObject var theme: Theme

    @ScaledMetric(relativeTo: .largeTitle) var scaledHeight = CGFloat(351)

    @ScaledMetric(relativeTo: .largeTitle) var scaledCardSize = CGFloat(168)

    @State var currentPage: Int? = 0

    var adjustedHeight: CGFloat {
        max(351, scaledHeight)
    }

    var adjustedCardSize: CGFloat {
        min(320, max(168, scaledCardSize))
    }

    var body: some View {
        VStack(spacing: 8) {
            header
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(Array(model.networks.enumerated()), id: \.offset) { index, network in
                        Button {
                            model.show(network: network)
                        } label: {
                            DiscoverNetworkCard(network: network, size: adjustedCardSize)
                        }
                        .buttonStyle(.plain)
                        .id(index)
                    }
                }
                .padding(.horizontal, 16)
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentPage, anchor: .leading)
            .onChange(of: currentPage) { _, page in
                guard let page else { return }

                model.pageDidChange(to: page + 1, totalPages: model.networks.count)
            }
            DiscoveryPageIndicatorView(numberOfItems: model.networks.count, currentPage: $currentPage)
            Rectangle()
                .foregroundColor(theme.primaryUi05)
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .frame(height: adjustedHeight)
    }

    var header: some View {
        HStack(alignment: .center) {
            Text(model.title)
                .foregroundStyle(theme.primaryText01)
                .font(size: 22, style: .title, weight: .bold)
                .lineLimit(2)
            Spacer()
            if model.showsShowAll {
                Button {
                    model.showAll()
                } label: {
                    Text(L10n.discoverShowAll.localizedUppercase)
                        .foregroundStyle(theme.primaryInteractive01)
                        .font(size: 13, style: .title, weight: .bold)
                        .kerning(0.6)
                }
            }
        }
        .padding(16)
    }
}

/// A network in the Discover row and in the expanded grid: round artwork above its name and description.
struct DiscoverNetworkCard: View {

    let network: NetworkListSummary

    /// The side length of the artwork, which the card is as wide as, or `nil` to fill the width it's given.
    var size: CGFloat?

    @Environment(\.sizeCategory) private var sizeCategory

    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(spacing: 10) {
            artwork
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            text
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(width: size)
        .accessibilityElement()
        .accessibilityLabel(network.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var artwork: some View {
        if let size {
            NetworkArtworkView(url: network.collectionImageURL, size: size)
                .clipShape(.circle)
        } else {
            NetworkArtworkView(url: network.collectionImageURL)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(.circle)
        }
    }

    /// The name and the description as one text, so that the line limit is theirs to share: a name
    /// long enough to wrap takes a line the description would have had.
    private var text: Text {
        switch (network.title, network.description) {
        case let (title?, description?):
            titleText(title) + Text(verbatim: "\n") + descriptionText(description)
        case let (title?, nil):
            titleText(title)
        case let (nil, description?):
            descriptionText(description)
        case (nil, nil):
            Text(verbatim: "")
        }
    }

    private func titleText(_ title: String) -> Text {
        Text(title)
            .font(.scaled(size: 15, style: .subheadline, weight: .medium, sizeCategory: sizeCategory))
            .foregroundStyle(theme.primaryText01)
            .kerning(-0.3)
    }

    private func descriptionText(_ description: String) -> Text {
        Text(description)
            .font(.scaled(size: 14, style: .subheadline, weight: .medium, sizeCategory: sizeCategory))
            .foregroundStyle(theme.primaryText02)
    }
}

/// A network's artwork, falling back to the grid placeholder while it loads or when there is none.
struct NetworkArtworkView: View {

    /// The network's collection image, or `nil` to draw the placeholder in its place.
    let url: URL?

    /// A fixed side length, or `nil` for the artwork to fill the space it's given.
    var size: CGFloat?

    var body: some View {
        Group {
            if let size {
                artwork.frame(width: size, height: size)
            } else {
                artwork.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .clipped()
    }

    @ViewBuilder
    private var artwork: some View {
        if let url {
            KFImage(url)
                .placeholder { _ in placeholder }
                .targetCache(ImageManager.sharedManager.discoverCache)
                .fade(duration: 0.25)
                .resizable()
                .scaledToFill()
        } else {
            placeholder.scaledToFill()
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if let image = ImageManager.sharedManager.placeHolderImage(.grid) {
            Image(uiImage: image)
                .resizable()
        }
    }
}

extension NetworkListSummary {
    var accessibilityLabel: String {
        [title, description].compactMap { $0 }.joined(separator: ", ")
    }

    var collectionImageURL: URL? {
        collectionImage.flatMap { URL(string: $0) }
    }
}

#if DEBUG

#Preview("Networks Row") {
    let model = DiscoverNetworksListModel()
    model.serverHandler = PreviewDiscoverServerHandler(
        podcastCollection: DiscoverPreviewData.networkCollection(title: "Networks")
    )
    model.populateFrom(item: DiscoverPreviewData.item(.networksList, title: "Networks"), region: "us", category: nil)

    return VStack(spacing: 0) {
        DiscoverNetworksListRowView(model: model)
        Spacer(minLength: 0)
    }
    .background(AppTheme.color(for: .primaryUi02, theme: Theme.sharedTheme))
    .environmentObject(Theme.sharedTheme)
}

#endif
