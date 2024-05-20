import PocketCastsServer
import PocketCastsUtils
import UIKit

class SmallPagedListSummaryViewController: DiscoverPeekViewController, GridLayoutDelegate, UICollectionViewDataSource, DiscoverSummaryProtocol, TinyPageControlDelegate {
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var showAllButton: ThemeableUIButton! {
        didSet {
            showAllButton.setTitle(L10n.discoverShowAll.localizedUppercase, for: .normal)
        }
    }

    @IBOutlet var titleLabel: ThemeableLabel!
    @IBOutlet var pageControl: TinyPageControl! {
        didSet {
            pageControl.delegate = self
        }
    }

    private var podcasts = [DiscoverPodcast]()
    private static let cellId = "smallPagedListCell"
    private let cellHeight = 48 as CGFloat
    private let numberOfRows = 4
    private var lastLayedOutWidth = 0 as CGFloat

    private let maxFeaturedItems = 20

    private var item: DiscoverItem?

    private weak var delegate: DiscoverDelegate?
    @IBOutlet var smallPagedCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet var dividerHeightConstraint: NSLayoutConstraint! {
        didSet {
            dividerHeightConstraint.constant = (1 / UIScreen.main.scale)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        (view as? ThemeableView)?.style = .primaryUi02

        maxCellWidth = view.bounds.width

        collectionView.register(UINib(nibName: "SmallListCell", bundle: nil), forCellWithReuseIdentifier: SmallPagedListSummaryViewController.cellId)

        cellSpacing = 16 as CGFloat
        isPeekEnabled = true

        let gridLayout = collectionView.collectionViewLayout as! GridLayout
        gridLayout.delegate = self
        gridLayout.numberOfRowsOrColumns = UInt(numberOfRows)
        gridLayout.scrollDirection = .horizontal
        gridLayout.itemSpacing = cellSpacing

        showAllButton.setLetterSpacing(0.6)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if lastLayedOutWidth != view.bounds.width {
            lastLayedOutWidth = view.bounds.width
            maxCellWidth = view.bounds.width
            smallPagedCollectionViewHeight.constant = (cellHeight + cellSpacing) * CGFloat(numberOfRows)
            updatePageCount()
            collectionView.layoutIfNeeded()
            collectionView.reloadData()
        }
    }

    @objc private func podcastStatusChanged(notification: Notification) {
        guard let object = notification.object else { return }
        let uuid = object as! String
        if let index = podcasts.firstIndex(where: { $0.uuid == uuid }), index < collectionView.numberOfItems(inSection: 0) {
            collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
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

    // MARK: - GridLayoutDelegate

    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt {
        1
    }

    func sizeForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> CGSize {
        CGSize(width: cellWidth, height: cellHeight)
    }

    // MARK: - UICollectionView Methods

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SmallPagedListSummaryViewController.cellId, for: indexPath) as! SmallListCell
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = item else { return }

        let podcast = podcasts[indexPath.item]

        delegate?.show(discoverPodcast: podcast, placeholderImage: nil, isFeatured: false, listUuid: item.uuid)

        collectionView.deselectItem(at: indexPath, animated: true)

        if let listId = item.uuid, let podcastUuid = podcast.uuid {
            AnalyticsHelper.podcastTappedFromList(listId: listId, podcastUuid: podcastUuid)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        podcasts.count > maxFeaturedItems ? maxFeaturedItems : podcasts.count
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        false
    }

    // MARK: - DiscoverSummaryProtocol

    func populateFrom(item: DiscoverItem, region: String?) {
        guard let source = delegate?.replaceRegionCode(string: item.source), let title = item.title?.localized else { return }

        self.item = item
        titleLabel.text = delegate?.replaceRegionName(string: title)

        DiscoverServerHandler.shared.discoverPodcastList(source: source, completion: { [weak self] podcastList in
            guard let strongSelf = self, let discoverPodcast = podcastList?.podcasts else { return }
            for podcast in discoverPodcast {
                strongSelf.podcasts.append(podcast)
            }

            DispatchQueue.main.async {
                strongSelf.updatePageCount()
                strongSelf.collectionView.reloadData()
            }
        })
    }

    // MARK: - TinyPageControl delegate

    func pageDidChange(_ newPage: Int) {
        let offset = CGFloat(newPage) * (cellWidth + cellSpacing)
        collectionView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
    }

    private func updatePageCount() {
        let displayedPodcastCount = podcasts.count > maxFeaturedItems ? maxFeaturedItems : podcasts.count
        let numberOfPages = CGFloat(displayedPodcastCount / numberOfRows)
        if numberOfPages == 0 { return }

        pageControl.numberOfPages = Int(ceil(numberOfPages))
        updateCurrentPage()
    }

    private func updateCurrentPage() {
        let currentPage = Int(round(collectionView.contentOffset.x / collectionView.frame.width))

        if currentPage == pageControl.currentPage { return }
        pageControl.currentPage = currentPage

        pageDidChange(to: currentPage, totalPages: pageControl.numberOfPages)
    }

    override func pageDidChange(to currentPage: Int, totalPages: Int) {
        guard let item else {
            return
        }

        Analytics.track(.discoverSmallListPageChanged, properties: ["current_page": currentPage + 1,
                                                                    "total_pages": totalPages,
                                                                    "list_id": item.inferredListId])
    }

    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        self.delegate = delegate
    }

    @IBAction func showAllClicked(_ sender: Any) {
        guard let delegate = delegate, let item = item else { return }

        delegate.showExpanded(item: item, podcasts: podcasts, podcastCollection: nil)
    }
}
