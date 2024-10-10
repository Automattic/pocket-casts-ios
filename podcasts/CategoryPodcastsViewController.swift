import PocketCastsServer
import UIKit
import PocketCastsUtils

class CategoryPodcastsViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    private static let cellId = "DiscoverCell"
    private static let sponsoredCellId = "CategorySponsoredCell"
    private static let promotionRow = 0
    @IBOutlet var podcastsTable: UITableView! {
        didSet {
            // This will remove extra separators from tableview
            podcastsTable.tableFooterView = UIView(frame: CGRect.zero)
            podcastsTable.register(UINib(nibName: "DiscoverPodcastTableCell", bundle: nil), forCellReuseIdentifier: CategoryPodcastsViewController.cellId)
            podcastsTable.register(UINib(nibName: "CategorySponsoredCell", bundle: nil), forCellReuseIdentifier: CategoryPodcastsViewController.sponsoredCellId)
        }
    }

    @IBOutlet var noNetworkView: UIView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!

    weak var delegate: DiscoverDelegate?

    fileprivate var item: DiscoverItem?

    fileprivate var category: DiscoverCategory? {
        didSet {
            title = category?.name?.localized
        }
    }
    private var skipCount: Int
    private var podcasts = [DiscoverPodcast]()
    private var promotion: DiscoverCategoryPromotion?
    fileprivate var region: String?

    init(category: DiscoverCategory? = nil, region: String?, skipCount: Int = 0) {
        self.category = category
        self.region = region
        self.skipCount = skipCount
        super.init(nibName: "CategoryPodcastsViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: podcastsTable)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if FeatureFlag.discoverCollectionView.enabled == false {
            loadPodcasts()
        }
    }

    @IBAction func tryAgainTapped(_ sender: AnyObject) {
        loadPodcasts()
    }

    // MARK: - UITableView Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        showPromotion() ? podcasts.count + 1 : podcasts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var podcastIndexRow = indexPath.row
        if showPromotion(), let promotion = promotion {
            if indexPath.row == CategoryPodcastsViewController.promotionRow {
                let cell = tableView.dequeueReusableCell(withIdentifier: CategoryPodcastsViewController.sponsoredCellId, for: indexPath) as! CategorySponsoredCell
                var isSubscribed = false
                if let delegate = delegate {
                    var discoverPodcast = DiscoverPodcast()
                    discoverPodcast.uuid = promotion.podcast_uuid
                    isSubscribed = delegate.isSubscribed(podcast: discoverPodcast)
                }
                cell.populateFrom(promotion, isSubscribed: isSubscribed)
                return cell
            } else {
                podcastIndexRow += 1
            }
        }

        let podcast = podcasts[podcastIndexRow]
        let cell = tableView.dequeueReusableCell(withIdentifier: CategoryPodcastsViewController.cellId, for: indexPath) as! DiscoverPodcastTableCell
        cell.subscribeSource = .discoverCategory
        cell.populateFrom(podcast, number: -1)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let delegate = delegate else { return }

        if let cell = tableView.cellForRow(at: indexPath) as? DiscoverPodcastTableCell {
            let podcast = podcasts[indexPath.row]

            let categoryName = category?.name ?? "unknown"
            let listUuid = "category-\(categoryName.lowercased())-\(region ?? "unknown")"

            delegate.show(discoverPodcast: podcast, placeholderImage: cell.podcastImage.image, isFeatured: false, listUuid: listUuid)
        } else if let cell = tableView.cellForRow(at: indexPath) as? CategorySponsoredCell, let promotion = promotion {
            var podcastInfo = PodcastInfo()
            podcastInfo.title = promotion.title
            podcastInfo.uuid = promotion.podcast_uuid
            let listId = promotion.promotion_uuid
            delegate.show(podcastInfo: podcastInfo, placeholderImage: cell.podcastImage.image, isFeatured: false, listUuid: listId)

            if let listId = listId, let uuid = podcastInfo.uuid {
                AnalyticsHelper.podcastTappedFromList(listId: listId, podcastUuid: uuid)
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if showPromotion(), indexPath.row == CategoryPodcastsViewController.promotionRow {
            return UIScreen.main.bounds.width > 360 ? 130 : 150
        }
        return 65
    }

    // MARK: - Loading

    private func loadPodcasts() {
        guard let delegate = delegate, let category, let source = delegate.replaceRegionCode(string: category.source) else { return }
        if loadingIndicator.isAnimating || podcasts.count > 0 { return }

        noNetworkView.isHidden = true
        loadingIndicator.startAnimating()

        DiscoverServerHandler.shared.discoverCategoryDetails(source: source, completion: { [weak self] categoryDetails in
            DispatchQueue.main.async {
                guard let strongSelf = self, let podcasts = categoryDetails?.podcasts else {
                    return
                }

                strongSelf.loadingIndicator.stopAnimating()
                strongSelf.podcasts = Array(podcasts.dropFirst(strongSelf.skipCount))
                strongSelf.promotion = categoryDetails?.promotion
                strongSelf.podcastsTable.reloadData()

                if let item = strongSelf.item {
                    strongSelf.delegate?.invalidate(item: item)
                }

                if let promotionUuid = categoryDetails?.promotion?.promotion_uuid {
                    AnalyticsHelper.listImpression(listId: promotionUuid)
                }
            }
        })
    }

    private func handleLoadFailed() {
        noNetworkView.isHidden = false
    }

    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        self.delegate = delegate
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    private func showPromotion() -> Bool {
        guard promotion != nil, !SubscriptionHelper.hasRenewingSubscription() else { return false }
        return true
    }
}

extension CategoryPodcastsViewController: DiscoverSummaryProtocol {
    func populateFrom(item: PocketCastsServer.DiscoverItem, region: String?, category: PocketCastsServer.DiscoverCategory?) {
        self.item = item
        if let category {
            self.category = category
        }
        self.region = region

        podcasts = []
        podcastsTable.reloadData()
        loadPodcasts()
    }
}
