import PocketCastsServer
import UIKit

class LargeListSummaryViewController: DiscoverPeekViewController, DiscoverSummaryProtocol, UICollectionViewDataSource, GridLayoutDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var divider: ThemeDividerView!
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet var titleLabel: ThemeableLabel!
    @IBOutlet var showAllBtn: UIButton! {
        didSet {
            showAllBtn.setTitle(L10n.discoverShowAll.localizedUppercase, for: .normal)
        }
    }

    private static let cellId = "LargeListCell"

    private var lastLayedOutWidth = 0 as CGFloat

    private var podcasts = [DiscoverPodcast]()
    private weak var delegate: DiscoverDelegate?
    private var item: DiscoverItem?

    @IBOutlet var largeListCollectionViewHeight: NSLayoutConstraint!

    var padding: CGFloat? {
        didSet {
            view.setNeedsLayout()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        (view as? ThemeableView)?.style = .primaryUi02

        collectionView.register(UINib(nibName: "LargeListCell", bundle: nil), forCellWithReuseIdentifier: LargeListSummaryViewController.cellId)

        collectionView.backgroundColor = UIColor.clear

        cellSpacing = 16 as CGFloat
        numVisibleColumns = 2
        isPeekEnabled = true

        let gridLayout = collectionView.collectionViewLayout as! GridLayout

        gridLayout.delegate = self
        gridLayout.numberOfRowsOrColumns = 1
        gridLayout.scrollDirection = .horizontal
        gridLayout.itemSpacing = cellSpacing

        showAllBtn.setLetterSpacing(0.6)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let padding {
            titleTopConstraint.constant = padding / 2
        }

        if lastLayedOutWidth != view.bounds.width {
            lastLayedOutWidth = view.bounds.width
            largeListCollectionViewHeight.constant = cellWidth + (padding ?? 50)
            collectionView.layoutIfNeeded()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        collectionView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let listId = item?.uuid {
            AnalyticsHelper.listImpression(listId: listId)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(podcastStatusChanged), name: Constants.Notifications.podcastAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(podcastStatusChanged), name: Constants.Notifications.podcastDeleted, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Constants.Notifications.podcastDeleted, object: nil)
        NotificationCenter.default.removeObserver(self, name: Constants.Notifications.podcastAdded, object: nil)
    }

    // MARK: - UICollectionView Methods

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LargeListSummaryViewController.cellId, for: indexPath) as! LargeListCell
        let thisPodcast = podcasts[indexPath.row]
        if let delegate = delegate {
            cell.populateFrom(thisPodcast, isSubscribed: delegate.isSubscribed(podcast: thisPodcast))
            cell.onSubscribe = { [weak self] in
                if let listId = self?.item?.uuid, let podcastUuid = thisPodcast.uuid {
                    AnalyticsHelper.podcastSubscribedFromList(listId: listId, podcastUuid: podcastUuid)
                }
                delegate.subscribe(podcast: thisPodcast)
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        podcasts.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = item else { return }

        let podcast = podcasts[indexPath.row]

        delegate?.show(discoverPodcast: podcast, placeholderImage: nil, isFeatured: false, listUuid: item.uuid)
        collectionView.deselectItem(at: indexPath, animated: true)

        if let listId = item.uuid, let podcastUuid = podcast.uuid {
            AnalyticsHelper.podcastTappedFromList(listId: listId, podcastUuid: podcastUuid)
        }
    }

    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        self.delegate = delegate
    }

    @objc private func podcastStatusChanged(notification: Notification) {
        guard let object = notification.object else { return }
        let uuid = object as! String
        if let index = podcasts.firstIndex(where: { $0.uuid == uuid }), index < collectionView.numberOfItems(inSection: 0) {
            collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
        }
    }

    // MARK: - GridLayoutDelegate

    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt {
        1
    }

    func sizeForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> CGSize {
        CGSize(width: cellWidth, height: cellWidth + 60)
    }

    // MARK: - Populate From Data

    func populateFrom(item: DiscoverItem) {
        guard let source = item.source else { return }
        guard let title = item.title?.localized else { return }

        showAllBtn.isHidden = item.expandedStyle == nil

        self.item = item
        titleLabel.text = delegate?.replaceRegionName(string: title)
        titleLabel.sizeToFit()
        divider.isHidden = true
        DiscoverServerHandler.shared.discoverPodcastList(source: source, completion: { [weak self] podcastList in
            guard let strongSelf = self, let discoverPodcast = podcastList?.podcasts else { return }

            let podcasts: [DiscoverPodcast]
            if let itemCount = item.summaryItemCount {
                podcasts = Array(discoverPodcast[0..<itemCount])
            } else {
                podcasts = discoverPodcast
            }

            for podcast in podcasts {
                strongSelf.podcasts.append(podcast)
            }

            DispatchQueue.main.async {
                strongSelf.divider.isHidden = false
                strongSelf.collectionView.reloadData()
            }
        })
    }

    // MARK: - IBActions

    @IBAction func showAllTapped(_ sender: Any) {
        guard let delegate = delegate, let item = item else { return }

        delegate.showExpanded(item: item, podcasts: podcasts, podcastCollection: nil)
    }

    // MARK: - Page Changed

    override func pageDidChange(to currentPage: Int, totalPages: Int) {
        guard let item else {
            return
        }

        Analytics.track(.discoverLargeListPageChanged, properties: ["current_page": currentPage,
                                                                    "total_pages": totalPages,
                                                                    "list_id": item.inferredListId])
    }
}
