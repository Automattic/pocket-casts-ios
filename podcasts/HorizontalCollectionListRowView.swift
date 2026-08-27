import SwiftUI
import Kingfisher
import PocketCastsServer

struct HorizontalCollectionListRowView: View {
    @ObservedObject var model: HorizontalCollectionModel

    @EnvironmentObject var theme: Theme

    @ScaledMetric(relativeTo: .largeTitle) private var scaledHeight = CGFloat(323)

    @ScaledMetric(relativeTo: .largeTitle) private var scaledRowHeight = CGFloat(210)

    @ScaledMetric(relativeTo: .largeTitle) private var scaledRowWidth = CGFloat(180)

    @State private var currentPage: Int? = 0

    private var adjustedHeight: CGFloat {
        max(323, scaledHeight)
    }

    private var adjustedRowHeight: CGFloat {
        min(320, max(210, scaledRowHeight))
    }

    private var adjustedRowWidth: CGFloat {
        min(320, max(180, scaledRowWidth))
    }

    private var podcastHeight: CGFloat {
        (adjustedRowHeight - 8) / 2
    }

    var body: some View {
        let pairs = model.list
        VStack(spacing: 8) {
            header
            GeometryReader { geometry in
                ScrollView([.horizontal]) {
                    LazyHStack(alignment: .top, spacing: 0) {
                        poster
                            .id(0)
                        list(pairs: pairs, width: geometry.size.width)
                        Spacer()
                            .frame(width: 24)
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentPage, anchor: .leading)
            }
            DiscoveryPageIndicatorView(numberOfItems: pairs.count + 1, currentPage: $currentPage)
            Rectangle()
                .foregroundColor(theme.primaryUi05)
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .frame(height: adjustedHeight)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text(model.type)
                .foregroundStyle(theme.primaryText01)
                .font(size: 22, style: .title, weight: .bold)
                .lineLimit(2)
            Spacer()
            Button {
                model.showCollection()
            } label: {
                Text(L10n.discoverShowAll.localizedUppercase)
                    .foregroundStyle(theme.primaryInteractive01)
                    .font(size: 13, style: .title, weight: .bold)
                    .kerning(0.6)
            }
        }
        .padding(16)
    }

    private var poster: some View {
        Button {
            model.showCollection()
        } label: {
            posterCard
        }
        .buttonStyle(.plain)
        .padding(.leading, 16)
    }

    private var posterCard: some View {
        ZStack(alignment: .bottom) {
            KFImage(model.posterImage)
                .placeholder { _ in
                    if let image = ImageManager.sharedManager.placeHolderImage(.grid) {
                        Image(uiImage: image)
                            .resizable()
                    } else {
                        Color.gray
                    }
                }
                .resizable()
                .scaledToFill()
                .frame(width: adjustedRowWidth, height: adjustedRowHeight)
                .clipped()
            VStack {
                Spacer()
                Text(model.title)
                    .foregroundStyle(.white)
                    .font(size: 13, style: .largeTitle, weight: .bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
                Spacer().frame(height: 8)
                Text(model.description)
                    .foregroundStyle(.white)
                    .font(size: 13, style: .largeTitle, weight: .regular)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
                Spacer().frame(height: 4)
            }
            .foregroundColor(.clear)
            .frame(width: adjustedRowWidth, height: adjustedRowHeight / 2)
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
        .frame(width: adjustedRowWidth, height: adjustedRowHeight)
    }

    private func row(for podcast: DiscoverPodcast) -> some View {
        HStack(alignment: .center, spacing: 0) {
            PodcastImageViewWrapper(podcastUUID: podcast.uuid ?? "", size: .grid)
                .frame(width: podcastHeight, height: podcastHeight)
            Spacer().frame(width: 10)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    ExplicitBadgeHelper.inlineTitle(podcast.title ?? "", isExplicit: podcast.isExplicit ?? false, theme: theme.activeTheme)
                        .foregroundStyle(theme.primaryText01)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                Spacer().frame(height: 8)
                HStack(spacing: 0) {
                    Text(podcast.author ?? "")
                        .foregroundStyle(theme.primaryText02)
                        .font(.footnote.weight(.medium))
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            .layoutPriority(1)
            SubscribeButtonView(podcastUuid: podcast.uuid ?? "", source: .discover) {
                model.subscribePodcast(podcast)
            }
        }
        .frame(height: podcastHeight)
        .onTapGesture {
            model.showPodcast(podcast)
        }
    }

    private func list(pairs: [[DiscoverPodcast]], width: CGFloat) -> some View {
        ForEach(pairs.indices, id: \.self) { index in
            VStack(spacing: 8) {
                ForEach(pairs[index], id: \.id) { podcast in
                    row(for: podcast)
                }
                if index == pairs.count - 1, pairs[index].count == 1 {
                    Rectangle()
                        .frame(height: podcastHeight)
                        .foregroundStyle(.clear)
                }
            }
            .padding(.leading, 16)
            .frame(width: max(width - 24, 0), height: adjustedRowHeight)
            .id(index + 1)
        }
    }
}
