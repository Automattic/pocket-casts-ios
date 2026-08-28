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

/// A network in the Discover row: round artwork above its name and description.
private struct DiscoverNetworkCard: View {

    let network: NetworkListSummary

    /// The side length of the artwork, which the card is as wide as.
    let size: CGFloat

    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(spacing: 10) {
            DiscoverNetworkArtwork(network: network, size: size)
                .clipShape(.circle)
            VStack(spacing: 2) {
                if let title = network.title {
                    Text(title)
                        .foregroundStyle(theme.primaryText01)
                        .font(size: 15, style: .subheadline, weight: .medium)
                        .kerning(-0.3)
                        .lineLimit(1)
                }
                if let description = network.description {
                    Text(description)
                        .foregroundStyle(theme.primaryText02)
                        .font(size: 14, style: .subheadline, weight: .medium)
                        .lineLimit(2)
                }
            }
            .multilineTextAlignment(.center)
        }
        .frame(width: size)
        .accessibilityElement()
        .accessibilityLabel(network.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }
}

/// A network as a poster: its artwork, with the name and description read out by VoiceOver.
struct DiscoverNetworkPoster: View {

    let network: NetworkListSummary

    /// A fixed side length, or `nil` for the poster to fill the space it's given.
    var size: CGFloat?

    var body: some View {
        DiscoverNetworkArtwork(network: network, size: size)
            .cornerRadius(4)
            .accessibilityElement()
            .accessibilityLabel(network.accessibilityLabel)
            .accessibilityAddTraits(.isButton)
    }
}

/// A network's artwork, falling back to the grid placeholder while it loads or when there is none.
private struct DiscoverNetworkArtwork: View {

    let network: NetworkListSummary

    /// A fixed side length, or `nil` for the artwork to fill the space it's given.
    var size: CGFloat?

    private var url: URL? {
        network.collectionImage.flatMap { URL(string: $0) }
    }

    private var placeholder: Image? {
        ImageManager.sharedManager.placeHolderImage(.grid).map { Image(uiImage: $0) }
    }

    var body: some View {
        if let size {
            artwork.frame(width: size, height: size)
        } else {
            artwork.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if let url {
            AsyncImageView(
                url: url,
                cache: ImageManager.sharedManager.discoverCache,
                placeholder: placeholder,
                contentMode: .fill
            )
        } else {
            placeholder?.resizable()
        }
    }
}

private extension NetworkListSummary {
    var accessibilityLabel: String {
        [title, description].compactMap { $0 }.joined(separator: ", ")
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
