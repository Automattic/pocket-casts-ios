import SwiftUI

/// Displays a title bar view with a dismiss button
struct BookmarkCardTitleView<Style: BookmarksStyle>: View {
    @ObservedObject var viewModel: BookmarkListViewModel
    @ObservedObject var style: Style

    var body: some View {
        ZStack(alignment: .leading) {
            HStack {
                Spacer()

                Text(L10n.bookmarks)
                    .font(style: .headline, weight: .semibold)

                Spacer()
            }

            Image("episode-close")
                .renderingMode(.template)
                .padding(5)
                .buttonize {
                    viewModel.dismiss()
                }
        }
        .foregroundStyle(style.primaryText)
        .opacity(viewModel.isMultiSelecting ? 0 : 1)
        .offset(y: viewModel.isMultiSelecting ? BookmarkListConstants.headerTransitionOffset : 0)
    }
}
