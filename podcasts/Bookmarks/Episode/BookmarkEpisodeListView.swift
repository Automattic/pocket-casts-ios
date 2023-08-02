import SwiftUI

struct BookmarkEpisodeListView: View {
    @ObservedObject var viewModel: BookmarkEpisodeListViewModel
    @ObservedObject var style = ThemedBookmarksStyle()
    var displayMode: DisplayMode = .list

    var body: some View {
        if displayMode == .list {
            BookmarksListView(viewModel: viewModel, style: style, showMoreInHeader: false)
                .padding(.top, 16)
        } else {
            VStack(spacing: BookmarkListConstants.padding) {
                headerView
                BookmarksListView(viewModel: viewModel, style: style, showMultiSelectInHeader: false)
            }
            .background(style.background.ignoresSafeArea())
        }
    }

    private var headerView: some View {
        VStack(spacing: Constants.padding) {
            ZStack {
                BookmarkCardTitleView(viewModel: viewModel, style: style)
                BookmarkListMultiSelectHeaderView(viewModel: viewModel, style: style)
            }
            .animation(.linear(duration: 0.2), value: viewModel.isMultiSelecting)
        }
        .padding(.top, Constants.padding)
        .padding(.horizontal, BookmarkListConstants.padding)
    }

    private enum Constants {
        static let padding = 14.0
    }

    enum DisplayMode {
        case list, standalone
    }
}
