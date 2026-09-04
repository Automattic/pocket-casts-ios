import PocketCastsServer
import SafariServices
import UIKit

enum CollectionCellStyle {
    case grid, descriptiveList
}

class ExpandedCollectionViewController: PCViewController, CollectionHeaderLinkDelegate {
    var item: DiscoverItem
    var podcastCollection: PodcastCollection?
    var podcasts: [DiscoverPodcast]
    weak var delegate: DiscoverDelegate?

    var cellStyle: CollectionCellStyle = .grid

    let inset: CGFloat = 16
    let bigDevicePortraitWidth: CGFloat = 500
    let gridStyleSpacing: CGFloat = 16
    let gridNumColumns: CGFloat = 2
    let gridPreferredWidth: CGFloat = 150
    let gridPeferredHeight: CGFloat = 265
    let descriptiveListPreferredMaxWidth: CGFloat = 280
    var descriptiveListPreferredMaxHeight: CGFloat {
        var baseHeight = CGFloat(200)
        let largeSize = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        if largeSize {
            baseHeight = baseHeight * 1.3
        }
        let metric = UIFontMetrics(forTextStyle: .callout)
        return max(baseHeight, metric.scaledValue(for: baseHeight))
    }
    let descriptiveListSpacing: CGFloat = 16

    @IBOutlet var collectionView: ThemeableCollectionView! {
        didSet {
            collectionView.register(UINib(nibName: "LargeListCell", bundle: nil), forCellWithReuseIdentifier: ExpandedCollectionViewController.gridCellId)
            collectionView.register(UINib(nibName: "DescriptiveCollectionCell", bundle: nil), forCellWithReuseIdentifier: ExpandedCollectionViewController.descriptiveCellId)
            collectionView.register(UINib(nibName: "DiscoverCollectionHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ExpandedCollectionViewController.headerId)
                collectionView.style = .primaryUi02
        }
    }

    @IBOutlet var collectionViewHeader: UICollectionReusableView!
    static let headerId = "DiscoverCollectionHeader"
    static let gridCellId = "LargeListCell"
    static let descriptiveCellId = "DescriptiveCollectionCell"
    private var lastWillLayoutWidth: CGFloat = 0

    init(item: DiscoverItem, podcasts: [DiscoverPodcast]) {
        self.item = item
        self.podcasts = podcasts

        super.init(nibName: "ExpandedCollectionViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        (view as? ThemeableView)?.style = .primaryUi02

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (controller: ExpandedCollectionViewController, _) in
            controller.updateSize()
        }

        title = navigationTitle

        if hasBleedingHeader {
            navTitleLabel.text = navigationTitle
            navTitleLabel.textColor = ThemeColor.primaryText01()
            navigationItem.titleView = {
                // The label has to go inside a container view, otherwise the bar changes its alpha
                let container = UIView()
                container.addSubview(navTitleLabel)
                navTitleLabel.anchorToAllSidesOf(view: container)
                return container
            }()
        }

        if item.source != nil && item.isAuthenticated == false {
            customRightBtn = UIBarButtonItem(image: UIImage(named: "podcast-share"), style: .plain, target: self, action: #selector(handleShare))
        }

        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: collectionView)
    }

    /// A network is titled by its name, the way its header is: its subtitle names its kind, so
    /// the bar would otherwise read "Network" on every one of them.
    private var navigationTitle: String? {
        if item.expandedStyle == "network_grid" {
            return podcastCollection?.title?.localized ?? item.title?.localized
        }

        return podcastCollection?.subtitle?.localized.localizedCapitalized ?? item.title?.localized.localizedCapitalized
    }

    /// True when the header's collage fills the space behind the navigation bar. Pre-26 bars are
    /// opaque, so there'd be nothing to see behind them, and a header-less screen has no collage.
    private var hasBleedingHeader: Bool {
        LiquidGlass.isEnabled && podcastCollection != nil
    }

    /// How far the header's collage runs above the content, so it fills the space behind the bar.
    var headerCollageBleed: CGFloat {
        hasBleedingHeader ? view.safeAreaInsets.top : 0
    }

    /// The collage gives the bar no background of its own, so the network's name would sit dark on
    /// dark. It fades in once the header's own title has scrolled under the bar instead.
    private lazy var navTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.alpha = 0
        return label
    }()

    /// How far into the content the header's own title sits, and so how far the user scrolls
    /// before the bar takes the title over.
    private let navTitleThreshold: CGFloat = 240

    private var isScrolledPastHeaderTitle = false

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateStatusBarStyle()

        guard hasBleedingHeader else { return }

        let scrolled = scrollView.contentOffset.y + scrollView.adjustedContentInset.top > navTitleThreshold
        guard scrolled != isScrolledPastHeaderTitle else { return }

        isScrolledPastHeaderTitle = scrolled
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) {
            self.navTitleLabel.alpha = scrolled ? 1 : 0
        }
    }

    private var isStatusBarOverCollage = false

    /// The collage is dark whichever theme is on, so the status bar takes its light style for as
    /// long as the collage is behind it.
    private func updateStatusBarStyle() {
        let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        let overCollage = hasBleedingHeader && collageBottom > statusBarHeight
        guard overCollage != isStatusBarOverCollage else { return }

        isStatusBarOverCollage = overCollage
        setNeedsStatusBarAppearanceUpdate()
    }

    /// Where the header's collage ends in this view, or zero once the header has scrolled away.
    private var collageBottom: CGFloat {
        let headers = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)
        guard let collage = (headers.first as? DiscoverCollectionHeader)?.collageImageView else { return 0 }

        return collage.convert(CGPoint(x: 0, y: collage.bounds.maxY), to: view).y
    }

    override func handleThemeChanged() {
        navTitleLabel.textColor = ThemeColor.primaryText01()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        for header in collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader) {
            (header as? DiscoverCollectionHeader)?.collageTopBleed = headerCollageBleed
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if lastWillLayoutWidth != view.bounds.width {
            lastWillLayoutWidth = view.bounds.width
            updateFlowLayoutSize()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateStatusBarStyle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if podcastCollection == nil {
            navigationController?.navigationBar.shadowImage = UIImage()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.navigationBar.shadowImage = nil
    }

    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        self.delegate = delegate
    }

    func linkTapped() {
        guard let link = podcastCollection?.webUrl, let url = URL(string: link) else { return }

        Analytics.track(.discoverCollectionLinkTapped, properties: ["list_id": item.inferredListId])

        if Settings.openLinks {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            present(SFSafariViewController(with: url), animated: true, completion: nil)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        isStatusBarOverCollage ? .lightContent : AppTheme.defaultStatusBarStyle()
    }

    @objc func handleShare() {
        guard let source = item.source, let url = URL(string: source)?.deletingPathExtension() else { return }
        Analytics.track(.discoverListShareTapped)
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityViewController, animated: true)
    }

    // MARK: - Dynamic Type support

    var cellExtraHeight: CGFloat {
        var baseHeight: CGFloat = 50
        let largeSize = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        if largeSize {
            baseHeight = baseHeight * 1.5
        }
        let metric = UIFontMetrics(forTextStyle: .callout)
        return max(baseHeight, metric.scaledValue(for: baseHeight))
    }

    func updateSize() {
        updateFlowLayoutSize()
    }
}

#if DEBUG

import SwiftUI

/// Hosts the expanded collection in a navigation controller, the way Discover pushes it.
private struct ExpandedCollectionPreview: UIViewControllerRepresentable {
    let makeController: () -> ExpandedCollectionViewController

    /// The controller holds its delegate weakly, so the preview is what keeps this one alive.
    private let delegate = PreviewDiscoverDelegate()

    init(_ makeController: @escaping () -> ExpandedCollectionViewController) {
        self.makeController = makeController
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = makeController()
        controller.registerDiscoverDelegate(delegate)

        // Pushed rather than made the root, so the preview carries the back button the real one has.
        let navigationController = PCNavigationController(rootViewController: UIViewController())
        navigationController.pushViewController(controller, animated: false)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

private let previewCollectionImage = "https://static.pocketcasts.com/discover/images/420/82e37e80-755d-0138-eddc-0acc26574db2.jpg"
private let previewNetworkImage = "https://static.pocketcasts.com/share/images/979866dc-fcb6-400d-8586-9e5003ef33b8-author.png"

#Preview("Grid") {
    ExpandedCollectionPreview {
        let controller = ExpandedCollectionViewController(
            item: DiscoverPreviewData.item(.collectionSummary, title: "Sounds for sleeping", expandedStyle: "grid"),
            podcasts: DiscoverPreviewData.podcasts(12)
        )
        controller.podcastCollection = DiscoverPreviewData.podcastCollection(
            title: "Sounds for sleeping",
            subtitle: "Staff picks",
            description: "Twelve shows for winding down, chosen by the people who make Pocket Casts.",
            podcasts: DiscoverPreviewData.podcasts(12),
            collectionImage: previewCollectionImage
        )
        return controller
    }
    .ignoresSafeArea()
}

#Preview("Network") {
    ExpandedCollectionPreview {
        let controller = ExpandedCollectionViewController(
            item: DiscoverPreviewData.item(.collectionSummary, title: "Relay", expandedStyle: "network_grid"),
            podcasts: DiscoverPreviewData.podcasts(12)
        )
        controller.podcastCollection = DiscoverPreviewData.podcastCollection(
            title: "Relay",
            subtitle: "NETWORK",
            description: "Independent podcasts about technology and the people who make it.",
            podcasts: DiscoverPreviewData.podcasts(12),
            collectionImage: previewNetworkImage
        )
        return controller
    }
    .ignoresSafeArea()
}

#Preview("Descriptive list") {
    ExpandedCollectionPreview {
        let controller = ExpandedCollectionViewController(
            item: DiscoverPreviewData.item(.collectionSummary, title: "Sounds for sleeping", expandedStyle: "descriptive_list"),
            podcasts: DiscoverPreviewData.podcasts(12)
        )
        controller.cellStyle = .descriptiveList
        return controller
    }
    .ignoresSafeArea()
}

#endif
