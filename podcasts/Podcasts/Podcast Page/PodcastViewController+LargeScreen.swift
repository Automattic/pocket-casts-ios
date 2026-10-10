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

        // Re-add the episodes and their multi-select footer, which drops their constraints, to
        // follow the list pane.
        let tableIndex = view.subviews.firstIndex(of: episodesTable) ?? 0
        episodesTable.removeFromSuperview()
        multiSelectFooter.removeFromSuperview()
        view.insertSubview(episodesTable, at: tableIndex)
        view.addSubview(multiSelectFooter)
        layout.install(in: self, below: episodesTable)
        // The empty loading container of the XIB is always behind the episodes, but it would
        // cover the header column
        loadingBgView.superview?.isHidden = true

        let listGuide = layout.listGuide
        let safeArea = view.safeAreaLayoutGuide
        let footerBottom = safeArea.bottomAnchor.constraint(equalTo: multiSelectFooter.bottomAnchor, constant: multiSelectFooterBottomConstraint.constant)
        let footerLeading = multiSelectFooter.leadingAnchor.constraint(equalTo: listGuide.leadingAnchor, constant: 8)
        footerLeading.priority = .defaultHigh
        let footerTrailing = listGuide.trailingAnchor.constraint(equalTo: multiSelectFooter.trailingAnchor, constant: 8)
        footerTrailing.priority = .defaultHigh
        NSLayoutConstraint.activate([
            episodesTable.topAnchor.constraint(equalTo: view.topAnchor),
            episodesTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            episodesTable.leadingAnchor.constraint(equalTo: listGuide.leadingAnchor),
            episodesTable.trailingAnchor.constraint(equalTo: listGuide.trailingAnchor),
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
    /// the tabs while the header has its own column.
    func updateLargeScreenLayoutIfNeeded() {
        guard let layout = largeScreenLayout, layout.update() else { return }

        // The episodes are transparent next to the header column, so its glow continues behind them
        blurHeaderView.isHidden = layout.isSplit
        episodesTable.isTransparent = layout.isSplit
        searchController?.isTransparent = layout.isSplit
        bookmarkList?.isTransparent = layout.isSplit
        updateLargeScreenHeader()
        scrollViewDidScroll(episodesTable)
        updateColors()
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
