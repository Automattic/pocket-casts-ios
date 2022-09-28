import PocketCastsServer
import UIKit

class FeaturedSummaryViewController: SimpleNotificationsViewController, GridLayoutDelegate, UICollectionViewDataSource, UICollectionViewDelegate, DiscoverSummaryProtocol, TinyPageControlDelegate {
    @IBOutlet var featuredCollectionView: UICollectionView!
    @IBOutlet var pageControl: TinyPageControl! {
        didSet {
            pageControl.delegate = self
        }
    }

    private var podcasts = [DiscoverPodcast]()
    private static let cellId = "FeaturedCollectionViewCell"

    private var maxCellWidth = 400 as CGFloat
    private let cellHeight = 181 as CGFloat
    private let cellSpacing = 0 as CGFloat
    private var listType: String = ""
    private var lastLayedOutWidth = 0 as CGFloat
    private let maxFeaturedItems = 5

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
            cell.populateFrom(podcast, isSubscribed: delegate.isSubscribed(podcast: podcast), listName: listType)
            cell.featuredView.onSubscribe = { delegate.subscribe(podcast: podcast) }
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
        delegate.show(discoverPodcast: podcast, placeholderImage: nil, isFeatured: true, listUuid: nil)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        podcasts.count
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    // MARK: - DiscoverSummaryProtocol

    func populateFrom(item: DiscoverItem) {
        guard let source = item.source, let title = item.title?.localized else { return }

        if let delegate = delegate {
            listType = delegate.replaceRegionName(string: title)
        }

        DiscoverServerHandler.shared.discoverPodcastList(source: source, completion: { [weak self] podcastList in
            guard let strongSelf = self, let discoverPodcast = podcastList?.podcasts else { return }

            for (index, discoverPodcast) in discoverPodcast.enumerated() {
                strongSelf.podcasts.append(discoverPodcast)

                if index == (strongSelf.maxFeaturedItems - 1) { break }
            }

            DispatchQueue.main.async {
                strongSelf.updatePageCount()
                strongSelf.featuredCollectionView.reloadData()
            }
        })
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
    }
}
