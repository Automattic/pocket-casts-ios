import SwiftUI
import UIKit

@available(iOS 27.1, *)
extension PlaylistDetailViewController {
    var largeScreenLayout: LargeScreenDetailsLayout? {
        largeScreenLayoutStorage as? LargeScreenDetailsLayout
    }

    func setUpLargeScreenLayout() {
        let background = PlaylistBlurHeaderView(viewModel: viewModel).themedUIView
        background.backgroundColor = .clear
        let layout = LargeScreenDetailsLayout(background: background)
        largeScreenLayoutStorage = layout
        layout.install(in: self, below: tableView)
        moveEpisodesToLargeScreenHost()
    }

    /// Moves the episodes and their multi-select footer to the view controller that shows them,
    /// with the search field in them
    private func moveEpisodesToLargeScreenHost() {
        guard let layout = largeScreenLayout else { return }

        let footerBottomConstant = multiSelectFooterBottomConstraint.constant
        layout.moveList([tableView, multiSelectFooter], children: [searchController]) { hostView in
            let safeArea = hostView.safeAreaLayoutGuide
            let footerBottomAnchor = LiquidGlass.isEnabled ? hostView.bottomAnchor : safeArea.bottomAnchor
            let footerBottom = footerBottomAnchor.constraint(equalTo: multiSelectFooter.bottomAnchor, constant: footerBottomConstant)
            multiSelectFooterBottomConstraint = footerBottom
            return [
                tableView.topAnchor.constraint(equalTo: hostView.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),
                blurHeaderView.heightAnchor.constraint(equalTo: hostView.widthAnchor, constant: 40),
                blurHeaderView.leadingAnchor.constraint(equalTo: hostView.leadingAnchor, constant: -20),
                blurHeaderView.trailingAnchor.constraint(equalTo: hostView.trailingAnchor, constant: 20),
                multiSelectFooter.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 8),
                safeArea.trailingAnchor.constraint(equalTo: multiSelectFooter.trailingAnchor, constant: 8),
                footerBottom
            ]
        }
    }

    /// Moves the header between its column and the first row of the episodes, which start with
    /// the search field while the header has its own column.
    func updateLargeScreenLayoutIfNeeded() {
        guard let layout = largeScreenLayout, layout.update() else { return }

        moveEpisodesToLargeScreenHost()
        if layout.isSplit {
            let header = PlaylistHeaderColumnView(viewModel: viewModel) { [weak layout] offset in
                layout?.headerScrollOffset = offset
            }
            layout.setHeaderController(UIHostingController(rootView: header.environmentObject(Theme.shared)))
        }

        // The empty state only covers the episodes while the header has its own column
        setContentUnavailableConfiguration(nil)
        layout.listPane.setContentUnavailableConfiguration(nil)
        // The episodes are transparent next to the header column, so its glow continues behind them
        blurHeaderView.isHidden = layout.isSplit || viewModel.episodes.isEmpty
        tableView.isTransparent = layout.isSplit
        updateColors()
        reloadEmptyState()
        updateNavTitleVisibility(animated: false)
    }
}

/// The playlist header in its own column next to the episodes, scrolling separately from them
@available(iOS 27.1, *)
private struct PlaylistHeaderColumnView: View {
    @ObservedObject var viewModel: PlaylistDetailViewModel
    let onScroll: (CGFloat) -> Void

    var body: some View {
        ScrollView {
            PlaylistHeaderView(viewModel: viewModel, isColumn: true)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, Constants.effectiveMiniPlayerOffset)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            onScroll(offset)
        }
    }
}
