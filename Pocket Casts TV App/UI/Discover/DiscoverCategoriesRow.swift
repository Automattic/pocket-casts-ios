import SwiftUI
import PocketCastsServer

struct DiscoverCategoriesRow: View {

    fileprivate enum Layout {
        static let cellWidth = CGFloat(568)
        static let cellHeight = CGFloat(258)
    }

    @State private var model: DiscoverCategoriesModel

    init(popularOnly: Bool) {
        _model = State(wrappedValue: DiscoverCategoriesModel(popularOnly: popularOnly))
    }

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView()
            case .empty:
                EmptyView()
            case .ready:
                list
            }
        }
        .task {
            await model.load()
        }
    }

    var list: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 48, content: {
                ForEach(model.categories, id: \.id) { category in
                    if category.id != nil {
                        NavigationLink(value: category) {
                            DiscoverCategoryCell(category: category)
                                .frame(width: Layout.cellWidth, height: Layout.cellHeight)
                        }
                        .buttonStyle(.card)
                        .setFocus(section: DiscoverType.categories)
                        .padding(.vertical, 24)
                    }
                }
            })
        }
    }
}
