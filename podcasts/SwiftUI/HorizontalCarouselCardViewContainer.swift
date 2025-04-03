import SwiftUI

struct HorizontalCarouselCardViewContainer<Item: HorizontalCarouselItemRepresentable>: View {
    private let spacing: CGFloat
    private let items: [Item]
    @Binding private var currentIndex: Int
    private let cardSize: CGSize
    private let hPadding: CGFloat
    private let peekAmount: CGFloat
    private let showPagination: Bool

    init(spacing: CGFloat = 16.0, items: [Item], currentIndex: Binding<Int>, cardSize: CGSize, hPadding: CGFloat = 24.0, peekAmount: CGFloat? = nil, showPagination: Bool = false) {
        self.spacing = spacing
        self.items = items
        self._currentIndex = currentIndex
        self.cardSize = cardSize
        self.hPadding = hPadding
        self.peekAmount = peekAmount ?? cardSize.width + spacing + hPadding + hPadding
        self.showPagination = showPagination
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                HorizontalCarousel(currentIndex: $currentIndex, items: items) { item in
                    HorizontalCarouselCard(item: item)
                        .frame(width: cardSize.width)
                        .frame(height: cardSize.height)
                        .id(item.id)
                }
                .carouselItemSpacing(spacing)
                .carouselPeekAmount(.constant(proxy.size.width - peekAmount))
                .carouselScrollEnabled(true)
                .padding(.horizontal, hPadding)
            }
            .frame(height: cardSize.height)
            if showPagination {
                PageIndicatorView(numberOfItems: items.count, currentPage: currentIndex)
                    .padding(.top, 16.0)
            }
        }
    }
}

fileprivate enum MockItem: String, CaseIterable, Identifiable, HorizontalCarouselItemRepresentable {
    case test

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
    HorizontalCarouselCardViewContainer(items: [MockItem.test, MockItem.test], currentIndex: .constant(0), cardSize: CGSize(width: 313, height: 370), showPagination: true)
}
