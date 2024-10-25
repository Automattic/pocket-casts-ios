import PocketCastsServer
import UIKit

class NetworkViewController: PCViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    @IBOutlet var networkImage: UIImageView!
    @IBOutlet var networkImageTopConstraint: NSLayoutConstraint!
    @IBOutlet var networkImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet var networkImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet var networksTable: UITableView! {
        didSet {
            networksTable.backgroundView = nil
            networksTable.backgroundColor = UIColor.clear
            networksTable.separatorColor = AppTheme.tableDividerColor()
            networksTable.sectionFooterHeight = 0.0
            networksTable.sectionHeaderHeight = 0.0
            networksTable.register(UINib(nibName: "PodcastGroupCell", bundle: nil), forCellReuseIdentifier: NetworkViewController.cellID)
        }
    }

    @IBOutlet var networkTableTopOffsetConstraint: NSLayoutConstraint!

    private static let defaultImageSize = 188.0 as CGFloat
    private static let topOffset = 260 as CGFloat
    private static let cellID = "PodcastEpCell"
    private static let cellSize = 64 as CGFloat
    private static let imageStartingOffset = 41 as CGFloat

    private let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 10))

    private var preloadedImage: UIImage?
    private var podcasts: [DiscoverPodcast]?
    private var network: PodcastNetwork

    @IBOutlet var loadingIndicator: UIActivityIndicatorView!

    private weak var delegate: DiscoverDelegate?

    init(network: PodcastNetwork, preloadedImage: UIImage?) {
        self.network = network
        super.init(nibName: "NetworkViewController", bundle: nil)
        self.preloadedImage = preloadedImage
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = network.title

        networksTable.contentInset = UIEdgeInsets(top: NetworkViewController.topOffset, left: 0, bottom: Constants.Values.miniPlayerOffset, right: 0)

        paddingView.backgroundColor = UIColor.clear

        setMainTintColor(AppTheme.viewBackgroundColor())
        networksTable.tableFooterView = paddingView

        networkImage.isHidden = true
        if let image = preloadedImage {
            networkImage.image = image
        } else {
            loadImage()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        loadNetworkPodcasts()
        NotificationCenter.default.addObserver(self, selector: #selector(subscribeRequested(_:)), name: Constants.Notifications.subscribeRequestedFromCell, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.shadowImage = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: Constants.Notifications.subscribeRequestedFromCell, object: nil)
    }

    override func handleThemeChanged() {
        networksTable.separatorColor = AppTheme.tableDividerColor()
    }

    @objc private func subscribeRequested(_ notification: Notification) {
        let cell = notification.object as! PodcastGroupCell
        let indexPath = networksTable.indexPath(for: cell)
        if let indexPath = indexPath, indexPath.row < podcasts?.count ?? 0, let podcastUuid = podcasts?[indexPath.row].uuid {
            ServerPodcastManager.shared.subscribe(to: podcastUuid, completion: nil)
        }
    }

    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        self.delegate = delegate
    }

    // MARK: - UITableView methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        podcasts?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: NetworkViewController.cellID)!
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let castCell = cell as? PodcastGroupCell else { return }
        if let podcast = podcasts?[indexPath.row] {
            castCell.populateFrom(podcast)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let delegate = delegate, let podcast = podcasts?[indexPath.row] {
            let cell = tableView.cellForRow(at: indexPath) as! PodcastGroupCell?
            delegate.show(discoverPodcast: podcast, placeholderImage: cell?.podcastImage.image, isFeatured: false, listUuid: nil)
        }
    }

    // MARK: - Scrolling support

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yPos = scrollView.contentOffset.y

        // change the size and position of the podcast image to match where the user has scrolled to
        if yPos < 0 {
            let percentageChange = abs(yPos) / NetworkViewController.topOffset
            if percentageChange >= 1 {
                let newImageSize = NetworkViewController.defaultImageSize + ((NetworkViewController.defaultImageSize * (percentageChange - 1)) * 0.5)

                networkImageHeightConstraint.constant = newImageSize
                networkImageWidthConstraint.constant = newImageSize
                networkImage.alpha = 1.0
                networkImageTopConstraint.constant = NetworkViewController.imageStartingOffset
            } else {
                networkImage.alpha = 1.0 * percentageChange
                networkImageTopConstraint.constant = NetworkViewController.imageStartingOffset * percentageChange
            }
        } else {
            networkImage.alpha = 0
        }
    }

    // MARK: - Loading

    private func loadNetworkPodcasts() {
        guard let source = network.source else { return }

        if loadingIndicator.isAnimating || podcasts != nil { return }

        loadingIndicator.startAnimating()
        DiscoverServerHandler.shared.discoverPodcastList(source: source) { [weak self] podcastList in
            guard let strongSelf = self, let podcastList = podcastList else { return }

            DispatchQueue.main.async {
                strongSelf.loadingIndicator.stopAnimating()

                strongSelf.podcasts = podcastList.podcasts
                strongSelf.networksTable.reloadData()
                if let color = strongSelf.network.color {
                    strongSelf.setMainTintColor(UIColor(hex: color))
                } else {
                    strongSelf.setMainTintColor(UIColor(hex: "#3D3D3D"))
                }
                strongSelf.networkImage.isHidden = false

                strongSelf.view.layoutIfNeeded()
            }
        }
    }

    private func loadImage() {
        if let imageUrl = network.imageUrl {
            ImageManager.sharedManager.loadNetworkImage(imageUrl: imageUrl, imageView: networkImage)
        }
    }

    private func setMainTintColor(_ color: UIColor) {
        view.backgroundColor = color
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }
}
