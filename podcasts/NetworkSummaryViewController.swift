import PocketCastsServer
import UIKit

class NetworkSummaryViewController: DiscoverPeekViewController, DiscoverSummaryProtocol, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GridLayoutDelegate {
    private static let cellId = "NetworkCell"

    private let maxCellSize = 400 as CGFloat
    private var lastLayedOutWidth = 0 as CGFloat

    private var networks = [PodcastNetwork]()
    private weak var delegate: DiscoverDelegate?

    @IBOutlet var networkCollectionViewHeight: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        (view as? ThemeableView)?.style = .primaryUi02

        collectionView.register(UINib(nibName: "NetworkCell", bundle: nil), forCellWithReuseIdentifier: NetworkSummaryViewController.cellId)

        cellSpacing = 16 as CGFloat
        numVisibleColumns = 2
        peekWidth = 20
        isPeekEnabled = true

        let gridLayout = collectionView.collectionViewLayout as! GridLayout
        gridLayout.delegate = self
        gridLayout.numberOfRowsOrColumns = 2
        gridLayout.scrollDirection = .horizontal
        gridLayout.itemSpacing = cellSpacing
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if lastLayedOutWidth != view.bounds.width {
            lastLayedOutWidth = view.bounds.width
            networkCollectionViewHeight.constant = (cellWidth * 2)
            collectionView.layoutIfNeeded()
        }
    }

    // MARK: - GridLayoutDelegate

    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt {
        1
    }

    func sizeForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> CGSize {
        CGSize(width: cellWidth, height: cellWidth)
    }

    // MARK: - UICollectionView Methods

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NetworkSummaryViewController.cellId, for: indexPath) as! NetworkCell

        cell.populateFrom(networks[indexPath.row])

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        networks.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let network = networks[indexPath.row]
        var preloadedImage: UIImage?
        if let cell = collectionView.cellForItem(at: indexPath) as? NetworkCell {
            preloadedImage = cell.networkImage.image
        }
        let networkViewController = NetworkViewController(network: network, preloadedImage: preloadedImage)
        if let delegate = delegate {
            networkViewController.registerDiscoverDelegate(delegate)
            delegate.navController()?.pushViewController(networkViewController, animated: true)
        }
    }

    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        self.delegate = delegate
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}

    // MARK: - Populate From Data

    func populateFrom(item: DiscoverItem, region: String?) {
        guard let source = item.source else { return }

        DiscoverServerHandler.shared.discoverNetworkList(source: source) { [weak self] podcastNetworks in
            guard let strongSelf = self, let podcastNetworks = podcastNetworks else { return }

            strongSelf.networks = podcastNetworks
            DispatchQueue.main.async {
                strongSelf.collectionView.reloadData()
            }
        }
    }

    // MARK: - Page Changed

    override func pageDidChange(to currentPage: Int, totalPages: Int) {
        Analytics.track(.discoverNetworkListPageChanged, properties: ["current_page": currentPage, "total_pages": totalPages])
    }
}
