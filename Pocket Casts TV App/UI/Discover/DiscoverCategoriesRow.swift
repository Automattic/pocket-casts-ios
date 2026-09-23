import SwiftUI
import PocketCastsServer

struct DiscoverCategoriesRow: View {

    fileprivate enum Layout {
        static let cellWidth = CGFloat(568)
        static let cellHeight = CGFloat(258)
    }

    @State private var model: DiscoverCategoriesModel

    init(item: DiscoverItem, popularOnly: Bool, source: String) {
        _model = State(wrappedValue: DiscoverCategoriesModel(item: item, popularOnly: popularOnly, source: source))
    }

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView()
            case .empty:
                EmptyView()
            case .failed:
                RowSection(title: L10n.tvHomeBrowseCategoriesSectionTitle, focusSection: DiscoverType.categories.rawValue) {
                    DiscoverRetryView(style: .row) { await model.retry() }
                }
            case .ready:
                RowSection(title: L10n.tvHomeBrowseCategoriesSectionTitle, focusSection: DiscoverType.categories.rawValue) {
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
                            DiscoverCategoryCell(category: category, colorIndex: index, source: model.source)
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
        .scrollClipDisabled()
    }
}
