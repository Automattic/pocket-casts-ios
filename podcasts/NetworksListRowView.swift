import PocketCastsServer
import SwiftUI

/// The Discover row for a `lists_list` item: the networks it contains, side by side.
struct NetworksListRowView: View {

    @ObservedObject var model: NetworksListModel

    @EnvironmentObject var theme: Theme

    @ScaledMetric(relativeTo: .largeTitle) var scaledHeight = CGFloat(293)

    @ScaledMetric(relativeTo: .largeTitle) var scaledCardSize = CGFloat(180)

    @State var currentPage: Int? = 0

    var adjustedHeight: CGFloat {
        max(293, scaledHeight)
    }

    var adjustedCardSize: CGFloat {
        min(320, max(180, scaledCardSize))
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

    var body: some View {
        VStack(spacing: 8) {
            header
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(model.networks.enumerated()), id: \.offset) { index, network in
                        Button {
                            model.show(network: network)
                        } label: {
                            NetworkPoster(network: network, size: adjustedCardSize)
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
            DiscoveryPageIndicatorView(numberOfItems: model.networks.count, currentPage: $currentPage)
            Rectangle()
                .foregroundColor(theme.primaryUi05)
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .frame(height: adjustedHeight)
    }
}

/// A network as a poster: its artwork, with the name and description over it.
struct NetworkPoster: View {

    let network: NetworkListSummary

    let size: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: network.collectionImage.flatMap { URL(string: $0) }) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                if let image = ImageManager.sharedManager.placeHolderImage(.grid) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.gray
                }
            }
            .frame(width: size, height: size)
            VStack(spacing: 8) {
                Spacer()
                Text(network.title ?? "")
                    .foregroundStyle(.white)
                    .font(size: 13, style: .largeTitle, weight: .bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(network.description ?? "")
                    .foregroundStyle(.white)
                    .font(size: 13, style: .largeTitle, weight: .regular)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Spacer().frame(height: 4)
            }
            .padding(.horizontal, 8)
            .frame(width: size, height: size / 2)
            .background(
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 0.16, green: 0.05, blue: 0.02).opacity(0), location: 0),
                        Gradient.Stop(color: Color(red: 0.09, green: 0.05, blue: 0.03), location: 1),
                    ],
                    startPoint: UnitPoint(x: 0.5, y: 0),
                    endPoint: UnitPoint(x: 0.5, y: 0.7)
                )
            )
        }
        .cornerRadius(4)
        .frame(width: size, height: size)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}
