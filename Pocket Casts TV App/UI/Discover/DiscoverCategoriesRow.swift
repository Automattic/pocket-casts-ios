import SwiftUI
import PocketCastsServer

struct DiscoverCategoriesRow: View {

    fileprivate enum Layout {
        static let cellWidth = CGFloat(568)
        static let cellHeight = CGFloat(258)
    }

    @State private var model: DiscoverCategoriesModel

    init(popularOnly: Bool, source: String) {
        _model = State(wrappedValue: DiscoverCategoriesModel(popularOnly: popularOnly, source: source))
    }

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView()
            case .empty:
                EmptyView()
            case .ready:
                HomeSection(title: L10n.tvHomeBrowseCategoriesSectionTitle, focusSection: DiscoverType.categories.rawValue) {
                    list
                }
            }
        }
        .task {
            await model.load()
        }
    }

    var list: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 48, content: {
                ForEach(Array(model.categories.enumerated()), id: \.element.id) { index, category in
                    if category.id != nil {
                        NavigationLink(value: category) {
                            DiscoverCategoryCell(category: category, colorIndex: index)
                                .frame(width: Layout.cellWidth, height: Layout.cellHeight)
                        }
                        .buttonStyle(.card)
                        .setFocus(section: DiscoverType.categories.rawValue)
                        .padding(.vertical, 24)
                        .simultaneousGesture(TapGesture().onEnded {
                            model.trackPillTapped(category)
                        })
                    }
                }
            })
        }
    }
}
