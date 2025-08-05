import SwiftUI
import Foundation

import PocketCastsServer

struct HorizontalCollectionList: View {

    @ObservedObject var model: HorizontalCollectionModel

    @EnvironmentObject var theme: Theme

    var header: some View {
        HStack {
            Text(model.type)
                .foregroundStyle(theme.primaryText01)
                .font(.title2.bold())
            Spacer()
            Button() {
                model.showCollection()
            } label: {
                Text(L10n.discoverShowAll.localizedUppercase)
                    .foregroundStyle(theme.primaryInteractive01)
                    .font(size: 13, style: .footnote, weight: .bold)
                    .kerning(0.6)
            }
        }
        .padding(16)
    }

    var poster: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: model.posterImage) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                if let image = ImageManager.sharedManager.placeHolderImage(.grid) {
                    Image(uiImage: image)
                } else {
                    Color.gray
                }
            }
            .frame(width: 179, height: 210)
            VStack() {
                Spacer().frame(height: 12)
                Text(model.title)
                    .foregroundStyle(.white)
                    .font(size: 13, style: .footnote, weight: .bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
                Spacer().frame(height: 8)
                Text(model.description)
                    .foregroundStyle(.white)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
                Spacer().frame(height: 12)
            }
            .foregroundColor(.clear)
            .frame(minWidth: 179, minHeight: 74)
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
        .frame(width: 179, height: 210)
        .padding(.leading, 16)
    }

    @ViewBuilder
    func row(for podcast: DiscoverPodcast) -> some View {
        HStack(alignment: .center, spacing: 10) {
            PodcastImageViewWrapper(podcastUUID: podcast.uuid ?? "", size: .grid)
                .frame(width: 101, height: 101)
            VStack(alignment: .leading) {
                HStack {
                    Text(podcast.title ?? "")
                        .foregroundStyle(theme.primaryText01)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                HStack {
                    Text(podcast.author ?? "")
                        .foregroundStyle(theme.primaryText02)
                        .font(.footnote.weight(.medium))
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            Spacer()
            SubscribeButtonView(podcastUuid: podcast.uuid ?? "", source: .discover) {
                model.subscribePodcast(podcast)
            }
        }
        .onTapGesture {
            model.showPodcast(podcast)
        }
    }

    @ViewBuilder
    func list(pairs: [[DiscoverPodcast]], width: CGFloat) -> some View {
        ForEach(0..<pairs.count, id: \.self) { index in
            VStack(spacing: 8) {
                ForEach(pairs[index], id: \.id) { podcast in
                    row(for: podcast)
                }
                if index == pairs.count - 1, pairs[index].count == 1 {
                    Rectangle()
                        .frame(height: 101)
                        .foregroundStyle(.clear)
                }
            }
            .padding(.leading, 16)
            .frame(width: max(width - 24, 0), height: 210)
            .id(index + 1)
        }
    }

    @State var currentPage: Int? = 0

    var body: some View {
        let pairs = model.list
        VStack(spacing: 8) {
            header
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView([.horizontal]) {
                        LazyHStack(alignment: .top, spacing: 0) {
                            poster
                                .id(0)
                            list(pairs: pairs, width: geometry.size.width)
                            Spacer()
                                .frame(width: 24)
                        }
                        .withScrollTargetLayout()
                    }
                    .scrollIndicators(.hidden)
                    .withPaging(minPage: 0, maxPage: pairs.count, currentPage: $currentPage, scrollProxy: proxy)
                }
            }
            DiscoveryPageIndicatorView(numberOfItems: pairs.count + 1, currentPage: $currentPage)
            Rectangle()
                .foregroundColor(theme.primaryUi05)
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .frame(height: 323)
    }
}

// MARK: - Special modifier to support versions previous than iOS 17
struct WithScrollTargetModifier: ViewModifier {

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.scrollTargetLayout()
        } else {
            content
        }
    }
}

extension View {
    func withScrollTargetLayout() -> some View {
        self.modifier(WithScrollTargetModifier())
    }
}

struct WithPagingModifier: ViewModifier {

    let minPage: Int
    let maxPage: Int
    @Binding var currentPage: Int?
    let scrollProxy: ScrollViewProxy

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentPage, anchor: .leading)
        } else {
            content.scrollDisabled(true)
                .gesture(DragGesture(minimumDistance: 3, coordinateSpace: .local)
                    .onEnded({ value in
                        if value.translation.width < 0 {
                            currentPage = min(maxPage, (currentPage ?? 0) + 1)
                        }

                        if value.translation.width > 0 {
                            currentPage = max(minPage, (currentPage ?? 0) - 1)
                        }
                    }))
                .onChange(of: currentPage) { newValue in
                    withAnimation {
                        scrollProxy.scrollTo(newValue, anchor: .leading)
                    }
                }
        }
    }
}


extension View {
    func withPaging(minPage: Int, maxPage: Int, currentPage: Binding<Int?>, scrollProxy: ScrollViewProxy) -> some View {
        return self.modifier(WithPagingModifier(minPage: minPage, maxPage: maxPage, currentPage: currentPage, scrollProxy: scrollProxy))
    }
}

struct HorizontalCarouselList_Previews: PreviewProvider {
    static var previews: some View {
        HorizontalCollectionList(model: HorizontalCollectionModel())
            .frame(height: 300)
    }
}
