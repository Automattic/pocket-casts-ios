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

        // Re-add the episodes and their multi-select footer, which drops their constraints, to
        // follow the list pane.
        let tableIndex = view.subviews.firstIndex(of: tableView) ?? 0
        tableView.removeFromSuperview()
        multiSelectFooter.removeFromSuperview()
        view.insertSubview(tableView, at: tableIndex)
        view.addSubview(multiSelectFooter)
        layout.install(in: self, below: tableView)

        let listGuide = layout.listGuide
        let safeArea = view.safeAreaLayoutGuide
        let footerBottomAnchor = LiquidGlass.isEnabled ? view.bottomAnchor : safeArea.bottomAnchor
        let footerBottom = footerBottomAnchor.constraint(equalTo: multiSelectFooter.bottomAnchor, constant: multiSelectFooterBottomConstraint.constant)
        let footerLeading = multiSelectFooter.leadingAnchor.constraint(equalTo: listGuide.leadingAnchor, constant: 8)
        footerLeading.priority = .defaultHigh
        let footerTrailing = listGuide.trailingAnchor.constraint(equalTo: multiSelectFooter.trailingAnchor, constant: 8)
        footerTrailing.priority = .defaultHigh
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: listGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: listGuide.trailingAnchor),
            blurHeaderView.heightAnchor.constraint(equalTo: listGuide.widthAnchor, constant: 40),
            blurHeaderView.leadingAnchor.constraint(equalTo: listGuide.leadingAnchor, constant: -20),
            blurHeaderView.trailingAnchor.constraint(equalTo: listGuide.trailingAnchor, constant: 20),
            footerLeading,
            footerTrailing,
            multiSelectFooter.leadingAnchor.constraint(greaterThanOrEqualTo: safeArea.leadingAnchor, constant: 8),
            safeArea.trailingAnchor.constraint(greaterThanOrEqualTo: multiSelectFooter.trailingAnchor, constant: 8),
            footerBottom
        ])
        multiSelectFooterBottomConstraint = footerBottom
    }

    /// Moves the header between its column and the first row of the episodes, which start with
    /// the search field while the header has its own column.
    func updateLargeScreenLayoutIfNeeded() {
        guard let layout = largeScreenLayout, layout.update() else { return }

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
