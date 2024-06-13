import PocketCastsServer
import UIKit

class FeaturedSummaryViewController: SimpleNotificationsViewController, GridLayoutDelegate, UICollectionViewDataSource, UICollectionViewDelegate, DiscoverSummaryProtocol, TinyPageControlDelegate {
    @IBOutlet var featuredCollectionView: ThemeableCollectionView!
    @IBOutlet var pageControl: TinyPageControl! {
        didSet {
            pageControl.delegate = self
        }
    }

    private var podcasts = [DiscoverPodcast]()
    private var sponsoredPodcasts = [DiscoverPodcast]()
    private var lists: [PodcastCollection] = []

    private static let cellId = "FeaturedCollectionViewCell"

    private var maxCellWidth = 400 as CGFloat
    private let cellHeight = 181 as CGFloat
    private let cellSpacing = 0 as CGFloat
    private var listType: String = ""
    private var lastLayedOutWidth = 0 as CGFloat
    private let maxFeaturedItems = 5

    private var listIdImpressionTracked: [String] = []

    private weak var delegate: DiscoverDelegate?
    @IBOutlet var featuredCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet var dividerHeightConstraint: NSLayoutConstraint! {
        didSet {
            dividerHeightConstraint.constant = (1 / UIScreen.main.scale)
        }
    }

    // MARK: - View Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        (view as? ThemeableView)?.style = .primaryUi02

        featuredCollectionView.register(UINib(nibName: "FeaturedCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: FeaturedSummaryViewController.cellId)

        let gridLayout = featuredCollectionView.collectionViewLayout as! GridLayout

        gridLayout.delegate = self
        gridLayout.numberOfRowsOrColumns = 1
        gridLayout.scrollDirection = .horizontal

        maxCellWidth = view.bounds.width

        NotificationCenter.default.addObserver(self, selector: #selector(podcastStatusChanged), name: Constants.Notifications.podcastAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(podcastStatusChanged), name: Constants.Notifications.podcastDeleted, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if lastLayedOutWidth != view.bounds.width {
            lastLayedOutWidth = view.bounds.width
            maxCellWidth = view.bounds.width
            featuredCollectionViewHeight.constant = cellHeight
            featuredCollectionView.reloadData()

            updatePageCount()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        featuredCollectionView.reloadData()
        featuredCollectionView.initializeAutoScrollTimer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        featuredCollectionView.stopAutoScrollTimer()
    }

    @objc private func podcastStatusChanged(notificiation: Notification) {
        guard let object = notificiation.object else { return }
        let uuid = object as! String
        if let index = podcasts.firstIndex(where: { $0.uuid == uuid }) {
            featuredCollectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
        }
    }

    // MARK: - GridLayoutDelegate

    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt {
        2
    }

    func sizeForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> CGSize {
        CGSize(width: maxCellWidth, height: cellHeight)
    }

    // MARK: - UICollectionView Methods

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeaturedSummaryViewController.cellId, for: indexPath) as! FeaturedCollectionViewCell

        let podcast = podcasts[indexPath.row]
        if let delegate = delegate {
            cell.populateFrom(podcast, isSubscribed: delegate.isSubscribed(podcast: podcast), listName: listType, isSponsored: sponsoredPodcasts.contains(podcast))
            cell.featuredView.onSubscribe = { [weak self] in
                if let listId = self?.listId(for: podcast), let podcastUuid = podcast.uuid {
                    AnalyticsHelper.podcastSubscribedFromList(listId: listId, podcastUuid: podcastUuid)
                }
                delegate.subscribe(podcast: podcast)
            }
        }

        if let uuid = podcast.uuid {
            ColorManager.darkThemeTintColorForPodcastUuid(uuid, completion: { (color: UIColor) in
                DispatchQueue.main.async {
                    cell.setPodcastColor(color)
                }
            })
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let delegate = delegate else { return }

        let podcast = podcasts[indexPath.row]
        let listId = listId(for: podcast)
        delegate.show(discoverPodcast: podcast, placeholderImage: nil, isFeatured: true, listUuid: listId)

        if let listId = listId, let podcastUuid = podcast.uuid {
            AnalyticsHelper.podcastTappedFromList(listId: listId, podcastUuid: podcastUuid)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        podcasts.count
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let podcast = podcasts[safe: indexPath.row],
              let listId = listId(for: podcast),
              !listIdImpressionTracked.contains(listId) else {
            return
        }

        AnalyticsHelper.listImpression(listId: listId)
        listIdImpressionTracked.append(listId)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        featuredCollectionView.initializeAutoScrollTimer()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        featuredCollectionView.stopAutoScrollTimer()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    // MARK: - DiscoverSummaryProtocol

    func populateFrom(item: DiscoverItem, region: String?) {
        guard let source = item.source, let title = item.title?.localized else { return }

        if let delegate = delegate {
            listType = delegate.replaceRegionName(string: title)
        }

        let dispatchGroup = DispatchGroup()

        var podcastsToShow: [DiscoverPodcast] = []

        var sponsoredPodcastsToAdd: [Int: DiscoverPodcast] = [:]

        dispatchGroup.enter()
        DiscoverServerHandler.shared.discoverPodcastList(source: source, completion: { podcastList in
            guard let discoverPodcast = podcastList?.podcasts else { return }

            podcastsToShow = discoverPodcast

            dispatchGroup.leave()
        })

        if let sponsoredPodcasts = item.sponsoredPodcasts {
            for sponsored in sponsoredPodcasts {
                if let source = sponsored.source, let position = sponsored.position {
                    dispatchGroup.enter()
                    DiscoverServerHandler.shared.discoverPodcastCollection(source: source, completion: { [weak self] podcastList in
                        guard let podcastList = podcastList, let discoverPodcast = podcastList.podcasts?.first else { return }

                        sponsoredPodcastsToAdd[position] = discoverPodcast

                        self?.lists.append(podcastList)

                        dispatchGroup.leave()
                    })
                }
            }
        }

        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self else {
                return
            }

            // Add featured podcasts
            self.podcasts = Array(podcastsToShow.prefix(self.maxFeaturedItems))

            // Add sponsored podcasts
            for sponsoredPodcastToAdd in sponsoredPodcastsToAdd {
                self.podcasts.insert(sponsoredPodcastToAdd.value, safelyAt: sponsoredPodcastToAdd.key)
            }
            self.sponsoredPodcasts = sponsoredPodcastsToAdd.map { $0.value }

            // Update and reload
            self.updatePageCount()
            self.featuredCollectionView.reloadData()
        }
    }

    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        self.delegate = delegate
    }

    // MARK: - TinyPageControl delegate

    func pageDidChange(_ newPage: Int) {
        let offset = CGFloat(newPage) * featuredCollectionView.bounds.width
        featuredCollectionView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
    }

    private func updatePageCount() {
        let numberOfPages = maxFeaturedItems < podcasts.count ? podcasts.count : maxFeaturedItems
        if numberOfPages == 0 { return }

        pageControl.numberOfPages = numberOfPages
        updateCurrentPage()
    }

    private func updateCurrentPage() {
        let currentPage = Int(round(featuredCollectionView.contentOffset.x / featuredCollectionView.frame.width))

        if currentPage == pageControl.currentPage { return }
        pageControl.currentPage = currentPage

        Analytics.track(.discoverFeaturedPageChanged, properties: ["current_page": currentPage + 1, "total_pages": pageControl.numberOfPages])
    }

    // MARK: - Sponsored Podcast methods

    func listId(for podcast: DiscoverPodcast) -> String? {
        lists.first(where: { $0.podcasts?.contains(podcast) ?? false })?.listId
    }
}
