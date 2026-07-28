import SwiftUI

class TransparentBookmarksStyle: ThemedBookmarksStyle {
    override var background: Color { Color.clear }
}

class BookmarksHostingCell: UITableViewCell {
    static let reuseIdentifier = "BookmarksListCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Prevent this cell from visually entering editing mode (no indentation or controls)
    override func setEditing(_ editing: Bool, animated: Bool) {
        // Intentionally ignore editing state to avoid shifting/indenting this embedded SwiftUI view
        super.setEditing(false, animated: animated)
    }

    func configure(with viewModel: BookmarkListViewModel, externalActionBarHandler: @escaping ((ExternalActionBarState) -> Void)) {
        // Wrap in a top-aligned container to avoid temporary vertical centering while sizing updates.
        contentConfiguration = UIHostingConfiguration {
            VStack(spacing: 0) {
                BookmarksListView(viewModel: viewModel,
                                  style: TransparentBookmarksStyle(),
                                  showHeader: true,
                                  showMultiSelectInHeader: false,
                                  allowInternalScrolling: false,
                                  showSearchField: true,
                                  useExternalActionBar: true,
                                  externalActionBarHandler: externalActionBarHandler)
                .padding(.top, 10)

                // Fills remaining space so content stays pinned to the top.
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .margins(.all, 0)
    }
}
