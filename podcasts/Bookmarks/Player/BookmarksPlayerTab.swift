import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct BookmarksPlayerTab: View {
    @ObservedObject var viewModel: BookmarkListViewModel
    @EnvironmentObject var theme: Theme

    @State private var showShadow = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            divider
            scrollView
        }
        .environmentObject(viewModel)
        .padding(.bottom)
        .background(theme.playerBackground01.ignoresSafeArea())
    }

    /// A static header view that displays the number of bookmarks and a ... more button
    private var headerView: some View {
        HStack {
            Text(L10n.bookmarkCount(viewModel.bookmarkCount))
                .foregroundStyle(theme.playerContrast02)
                .font(size: 14, style: .subheadline)

            Spacer()

            Image("more").foregroundStyle(theme.playerContrast01).buttonize {
                print("NOOP")
            }
        }
        .padding(.horizontal, Constants.padding)
        .padding(.bottom, Constants.headerPadding)
    }

    private var scrollView: some View {
        ZStack(alignment: .top) {
            ScrollViewWithContentOffset {
                LazyVStack(spacing: 0) {
                    //   enumerated to get both the index and the bookmark to hide the last divider
                    ForEach(Array(viewModel.bookmarks.enumerated()), id: \.element.id) { index, bookmark in
                        BookmarkRow(bookmark: bookmark)

                        if index < viewModel.bookmarkCount-1 {
                            divider
                        }
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
        Divider().background(theme.playerContrast05)
    }

    private enum Constants {
        static let shadowHeight = 20.0
        static let padding = 16.0
        static let headerPadding = 12.0
    }
}

// MARK: - Previews

struct BookmarksPlayerTab_Previews: PreviewProvider {
    static var previews: some View {
        BookmarksPlayerTab(viewModel: .init(bookmarkManager: .init()))
            .setupDefaultEnvironment()
    }
}
