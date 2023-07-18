import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct BookmarksPlayerTab: View {
    @ObservedObject var viewModel: BookmarkListViewModel
    @ObservedObject var style: BookmarksPlayerTabStyle = .init()

    @State private var showShadow = false

    private var actionBarVisible: Bool {
        viewModel.isMultiSelecting && viewModel.numberOfSelectedItems > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            divider

            actionBarView {
                scrollView
            }
        }
        .environmentObject(viewModel)
        .padding(.bottom)
        .background(style.background.ignoresSafeArea())
    }

    /// A static header view that displays the number of bookmarks and a ... more button
    private var headerView: some View {
        // Using a ZStack here to prevent the header from changing height when switching between modes
        ZStack {
            HStack {
                Text(L10n.bookmarkCount(viewModel.numberOfItems))
                    .foregroundStyle(style.secondaryText)
                    .font(size: 14, style: .subheadline)

                Spacer()

                Image("more").foregroundStyle(style.primaryText).buttonize {
                    viewModel.showMoreOptions()
                }
            }
            .opacity(viewModel.isMultiSelecting ? 0 : 1)
            .offset(y: viewModel.isMultiSelecting ? Constants.headerTransitionOffset : 0)

            multiSelectionHeaderView
        }
        .padding(.horizontal, Constants.padding)
        .padding(.bottom, Constants.headerPadding)
    }

    /// A header view that appears when we're in the multi selection mode
    private var multiSelectionHeaderView: some View {
        HStack {
            Button(viewModel.hasSelectedAll ? L10n.deselectAll : L10n.selectAll) {
                viewModel.toggleSelectAll()
            }

            Spacer()

            Button(L10n.cancel) {
                withAnimation {
                    viewModel.toggleMultiSelection()
                }
            }
        }
        .font(style: .body)
        .foregroundStyle(style.primaryText)
        .opacity(viewModel.isMultiSelecting ? 1 : 0)
        .offset(y: viewModel.isMultiSelecting ? 0 : -Constants.headerTransitionOffset)
    }

    private var scrollView: some View {
        ZStack(alignment: .top) {
            ScrollViewWithContentOffset {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.items) { bookmark in
                        BookmarkRow(bookmark: bookmark, style: style)

                        if !viewModel.isLast(item: bookmark) {
                            divider
                        }
                    }

                    // Add padding to the bottom of the list when the action bar is visible so it's not blocking the view
                    if actionBarVisible {
                        Spacer(minLength: Constants.multiSelectionBottompadding)
                    }
                }
            }
            .onContentOffsetChange { contentOffset in
                showShadow = Int(contentOffset.y) < 0
            }

            // Shadow overlay
            shadowView
        }
    }

    @ViewBuilder
    private func actionBarView<Content: View>(_ content: @escaping () -> Content) -> some View {
        let title = L10n.selectedCountFormat(viewModel.numberOfSelectedItems)
        let editVisible = viewModel.numberOfSelectedItems == 1

        ActionBarOverlayView(actionBarVisible: actionBarVisible, title: title, style: style.actionBarStyle, content: {
            content()
        }, actions: [
            .init(imageName: "folder-edit", title: L10n.edit, visible: editVisible, action: {
                viewModel.editSelectedBookmarks()
            }),
            .init(imageName: "delete", title: L10n.delete, action: {
                viewModel.deleteSelectedBookmarks()
            })
        ])
    }

    // MARK: - Utility Views

    /// A shadow view that adds depth between the scroll view and the static header
    private var shadowView: some View {
        LinearGradient(colors: [.black.opacity(0.2), .black.opacity(0)], startPoint: .top, endPoint: .bottom)
            .frame(maxWidth: .infinity, maxHeight: Constants.shadowHeight)
            .opacity(showShadow ? 1 : 0)
            .animation(.linear(duration: 0.2), value: showShadow)
    }

    /// Styled divider view
    private var divider: some View {
        Divider().background(style.divider)
    }

    private enum Constants {
        static let shadowHeight = 20.0
        static let padding = 16.0
        static let headerPadding = 12.0
        static let headerTransitionOffset = 10.0
        static let multiSelectionBottompadding = 70.0
    }
}

// MARK: - Previews

struct BookmarksPlayerTab_Previews: PreviewProvider {
    static var previews: some View {
        BookmarksPlayerTab(viewModel: .init(bookmarkManager: .init(), sortOption: .init("", defaultValue: .newestToOldest)))
            .setupDefaultEnvironment()
    }
}
