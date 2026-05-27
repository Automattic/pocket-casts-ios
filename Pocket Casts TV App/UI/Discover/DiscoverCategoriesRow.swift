import SwiftUI
import PocketCastsServer

struct DiscoverCategoriesRow: View {

    fileprivate enum Layout {
        static let gridSize = CGFloat(250)
    }

    @State private var model = DiscoverCategoriesModel()


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
                                .frame(width: 568, height: 258)
                        }
                        .buttonStyle(.card)
                        .padding(.vertical, 24)
                    }
                }
            })
        }
    }
}
