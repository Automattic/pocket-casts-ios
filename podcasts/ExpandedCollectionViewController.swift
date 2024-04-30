import PocketCastsServer
import SafariServices
import UIKit

enum CollectionCellStyle {
    case grid, descriptive_list
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
    let descriptiveListPreferredMaxHeight: CGFloat = 200
    let descriptiveListSpacing: CGFloat = 16

    @IBOutlet var collectionView: ThemeableCollectionView! {
        didSet {
            collectionView.register(UINib(nibName: "LargeListCell", bundle: nil), forCellWithReuseIdentifier: ExpandedCollectionViewController.gridCellId)
            collectionView.register(UINib(nibName: "DescriptiveCollectionCell", bundle: nil), forCellWithReuseIdentifier: ExpandedCollectionViewController.descriptiveCellId)
            collectionView.register(UINib(nibName: "DiscoverCollectionHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ExpandedCollectionViewController.headerId)
            collectionView.style = .primaryUi02
            if PlaybackManager.shared.currentEpisode() != nil {
                collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Constants.Values.miniPlayerOffset, right: 0)
            }
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

        if let collectionSubtitle = podcastCollection?.subtitle?.localized.localizedCapitalized {
            title = collectionSubtitle
        } else {
            title = item.title?.localized.localizedCapitalized
        }

        addCustomObserver(Constants.Notifications.miniPlayerDidDisappear, selector: #selector(miniPlayerStatusDidChange))
        addCustomObserver(Constants.Notifications.miniPlayerDidAppear, selector: #selector(miniPlayerStatusDidChange))

        miniPlayerStatusDidChange()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if lastWillLayoutWidth != view.bounds.width {
            lastWillLayoutWidth = view.bounds.width
            updateFlowLayoutSize()
        }
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
        NotificationCenter.default.removeObserver(self)
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
        AppTheme.defaultStatusBarStyle()
    }

    @objc private func miniPlayerStatusDidChange() {
        collectionView.updateContentInset(multiSelectEnabled: false)
    }
}
