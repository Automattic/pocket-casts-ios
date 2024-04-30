import PocketCastsServer
import UIKit

class PodcastHeaderListViewController: PCViewController, UITableViewDataSource, UITableViewDelegate {
    private var podcasts: [DiscoverPodcast]

    var showFeaturedCell = false
    var showRankingNumber = false
    var labelTitle: String?

    @IBOutlet var chartsTable: UITableView!

    private weak var delegate: DiscoverDelegate?
    private static let cellId = "DiscoverCell"
    private static let featuredCellId = "FeaturedTableViewCell"

    init(podcasts: [DiscoverPodcast]) {
        self.podcasts = podcasts

        super.init(nibName: "PodcastHeaderListViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        chartsTable.register(UINib(nibName: "DiscoverPodcastTableCell", bundle: nil), forCellReuseIdentifier: PodcastHeaderListViewController.cellId)
        chartsTable.register(UINib(nibName: "FeaturedTableViewCell", bundle: nil), forCellReuseIdentifier: PodcastHeaderListViewController.featuredCellId)

        addCustomObserver(Constants.Notifications.miniPlayerDidAppear, selector: #selector(miniPlayerStatusDidChange))
        addCustomObserver(Constants.Notifications.miniPlayerDidDisappear, selector: #selector(miniPlayerStatusDidChange))

        chartsTable.updateContentInset(multiSelectEnabled: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        chartsTable.reloadData()
    }

    @objc func miniPlayerStatusDidChange() {
        chartsTable.updateContentInset(multiSelectEnabled: false)
    }

    // MARK: - UITableView Methods

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if showFeaturedCell, indexPath.row == 0 {
            return 181.0
        }
        return 65
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        podcasts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let podcast = podcasts[indexPath.row]
        var cell: UITableViewCell
        if showFeaturedCell, indexPath.row == 0 {
            let featuredCell = tableView.dequeueReusableCell(withIdentifier: PodcastHeaderListViewController.featuredCellId, for: indexPath) as! FeaturedTableViewCell
            featuredCell.populateFrom(podcast, listName: labelTitle ?? L10n.top)
            featuredCell.showRanking()
            if let uuid = podcast.uuid {
                ColorManager.darkThemeTintColorForPodcastUuid(uuid, completion: { (color: UIColor) in
                    DispatchQueue.main.async {
                        featuredCell.setPodcastColor(color)
                    }
                })
            }
            cell = featuredCell as UITableViewCell
        } else {
            let discoverCell = tableView.dequeueReusableCell(withIdentifier: PodcastHeaderListViewController.cellId, for: indexPath) as! DiscoverPodcastTableCell
            discoverCell.subscribeSource = .discoverRankedList
            if showRankingNumber {
                discoverCell.populateFrom(podcast, number: indexPath.row + 1)
            } else {
                discoverCell.populateFrom(podcast, number: 0)
            }
            cell = discoverCell as UITableViewCell
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let delegate = delegate {
            let podcast = podcasts[indexPath.row]
            delegate.show(discoverPodcast: podcast, placeholderImage: nil, isFeatured: false, listUuid: nil)
        }
    }

    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        self.delegate = delegate
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }
}
