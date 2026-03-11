import SwiftUI

struct HorizontalCarouselCardViewContainer<Item: HorizontalCarouselItemRepresentable>: View {
    private let spacing: CGFloat
    private let items: [Item]
    private let cardSize: CGSize
    private let hPadding: CGFloat
    private let showPagination: Bool
    private let paginationColor: Color

    @Binding private var currentIndex: Int?

    private var currentIndexNonOptional: Binding<Int> {
        Binding<Int>(
            get: { currentIndex ?? 0 },
            set: { currentIndex = $0 }
        )
    }

    init(spacing: CGFloat = 16.0, items: [Item], currentIndex: Binding<Int?>, cardSize: CGSize, hPadding: CGFloat = 24.0, showPagination: Bool = false, paginationColor: Color) {
        self.spacing = spacing
        self.items = items
        self._currentIndex = currentIndex
        self.cardSize = cardSize
        self.hPadding = hPadding
        self.showPagination = showPagination
        self.paginationColor = paginationColor
    }

    var body: some View {
        VStack(spacing: 0) {
            if #available(iOS 17.0, *) {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: spacing) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                            HorizontalCarouselCard(item: item)
                                .frame(width: cardSize.width)
                                .frame(maxHeight: cardSize.height)
                                .id(i)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .safeAreaPadding(.horizontal, hPadding)
                .scrollPosition(id: $currentIndex)
                .scrollIndicators(.hidden)
                .frame(maxHeight: cardSize.height)
            } else {
                GeometryReader { proxy in
                    HorizontalCarousel(currentIndex: currentIndexNonOptional, items: items) { item in
                        HorizontalCarouselCard(item: item)
                            .frame(width: cardSize.width)
                            .frame(maxHeight: cardSize.height)
                            .id(item.id)
                    }
                    .carouselItemSpacing(spacing)
                    .carouselPeekAmount(.constant(proxy.size.width - (cardSize.width + spacing + hPadding + hPadding)))
                    .carouselScrollEnabled(true)
                    .padding(.horizontal, hPadding)
                }
                .frame(maxHeight: cardSize.height)
            }
            if showPagination {
                PageIndicatorView(numberOfItems: items.count, currentPage: currentIndex ?? 0)
                    .foregroundColor(paginationColor)
                    .padding(.top, 16.0)
            }
        }
    }
}

fileprivate enum MockItem: String, CaseIterable, Identifiable, HorizontalCarouselItemRepresentable {
    case test
    case test2

    var backgroundColor: Color {
        .red
    }

    var titleColor: Color {
        .black
    }

    var titleSize: CGFloat {
        18.0
    }

    var textColor: Color {
        .gray
    }

    var textSize: CGFloat {
        14.0
    }

    var title: String {
        "Lorem Ipsum dolor sit amet"
    }

    var text: String {
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    }

    var image: String {
        "plus_feature_card_desktop"
    }
}

#Preview {
    HorizontalCarouselCardViewContainer(
        items: [MockItem.test, MockItem.test2],
        currentIndex: .constant(0),
        cardSize: CGSize(width: 313, height: 370),
        hPadding: 24,
        showPagination: true,
        paginationColor: .black)
}
