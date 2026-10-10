import SwiftUI
import UIKit

@available(iOS 27.1, *)
extension PodcastViewController {
    var largeScreenLayout: LargeScreenDetailsLayout? {
        largeScreenLayoutStorage as? LargeScreenDetailsLayout
    }

    func setUpLargeScreenLayout() {
        let background = PodcastBlurHeaderView(podcastUUID: podcastUUID).uiView
        background.backgroundColor = .clear
        let layout = LargeScreenDetailsLayout(background: background)
        largeScreenLayoutStorage = layout
        layout.install(in: self, below: episodesTable)
        // The empty loading container of the XIB is always behind the episodes, but it would
        // cover the header column
        loadingBgView.superview?.isHidden = true
        moveEpisodesToLargeScreenHost()
    }

    /// Moves the header between its column and the first row of the episodes, which start with
    /// the tabs while the header has its own column.
    func updateLargeScreenLayoutIfNeeded() {
        guard let layout = largeScreenLayout, layout.update() else { return }

        moveEpisodesToLargeScreenHost()
        // The episodes are transparent next to the header column, so its glow continues behind them
        blurHeaderView.isHidden = layout.isSplit
        episodesTable.isTransparent = layout.isSplit
        searchController?.isTransparent = layout.isSplit
        bookmarkList?.isTransparent = layout.isSplit
        updateLargeScreenHeader()
        scrollViewDidScroll(episodesTable)
        updateColors()
    }

    /// Gives the pane that shows the episodes the view controllers they host, such as the bookmark
    /// list's search field, created after the episodes moved
    func adoptLargeScreenListChildren() {
        largeScreenLayout?.adoptListChildren(largeScreenListChildren)
    }

    /// The view controllers in the episodes, which move with them
    private var largeScreenListChildren: [UIViewController] {
        [searchController, bookmarkList?.searchHeaderController, createdPodcastHeaderCell?.hostingController].compactMap { $0 }
    }

    /// Moves the episodes and their multi-select footer to the view controller that shows them
    private func moveEpisodesToLargeScreenHost() {
        guard let layout = largeScreenLayout else { return }

        let footerBottomConstant = multiSelectFooterBottomConstraint.constant
        layout.moveList([episodesTable, multiSelectFooter], children: largeScreenListChildren) { hostView in
            let safeArea = hostView.safeAreaLayoutGuide
            let footerBottom = safeArea.bottomAnchor.constraint(equalTo: multiSelectFooter.bottomAnchor, constant: footerBottomConstant)
            multiSelectFooterBottomConstraint = footerBottom
            return [
                episodesTable.topAnchor.constraint(equalTo: hostView.topAnchor),
                episodesTable.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
                episodesTable.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
                episodesTable.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),
                blurHeaderView.heightAnchor.constraint(equalTo: hostView.widthAnchor, constant: 40),
                blurHeaderView.leadingAnchor.constraint(equalTo: hostView.leadingAnchor, constant: -20),
                blurHeaderView.trailingAnchor.constraint(equalTo: hostView.trailingAnchor, constant: 20),
                multiSelectFooter.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 8),
                safeArea.trailingAnchor.constraint(equalTo: multiSelectFooter.trailingAnchor, constant: 8),
                footerBottom
            ]
        }
    }

    /// Shows the header in its column once the podcast has loaded
    func updateLargeScreenHeader() {
        guard let layout = largeScreenLayout, layout.isSplit, !layout.hasHeaderController, podcast != nil else { return }

        let header = PodcastHeaderColumnView(viewModel: podcastHeaderViewModel) { [weak layout] offset in
            layout?.headerScrollOffset = offset
        }
        layout.setHeaderController(UIHostingController(rootView: header.setupDefaultEnvironment()))
    }
}

/// The podcast header in its own column next to the episodes, scrolling separately from them
@available(iOS 27.1, *)
private struct PodcastHeaderColumnView: View {
    @ObservedObject var viewModel: PodcastHeaderViewModel
    let onScroll: (CGFloat) -> Void

    var body: some View {
        ScrollView {
            PodcastHeaderView(viewModel: viewModel, isColumn: true)
                .padding(.bottom, Constants.effectiveMiniPlayerOffset)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            onScroll(offset)
        }
    }
}
