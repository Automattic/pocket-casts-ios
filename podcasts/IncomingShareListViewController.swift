import PocketCastsServer
import UIKit

class IncomingShareListViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var listTitle: UILabel!
    @IBOutlet var listDescription: UITextView!
    @IBOutlet var podcastCount: UILabel!
    @IBOutlet var podcastsTable: UITableView! {
        didSet {
            podcastsTable.register(UINib(nibName: "DiscoverPodcastTableCell", bundle: nil), forCellReuseIdentifier: IncomingShareListViewController.cellId)
        }
    }

    private static let cellId = "DiscoverCell"

    @IBOutlet var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var footerView: UIView!

    private var jsonLocation: String
    private var podcasts = [DiscoverPodcast]()

    @objc init(jsonLocation: String) {
        self.jsonLocation = jsonLocation

        super.init(nibName: "IncomingShareListViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        customRightBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(IncomingShareListViewController.doneTapped))
        super.viewDidLoad()

        title = L10n.sharedList
        loadSharedPodcasts()

        let footer = UIView(frame: CGRect(x: 0, y: 0, width: podcastsTable.bounds.width, height: 55))
        podcastsTable.tableFooterView = footer
        footer.addSubview(footerView)
        footerView.anchorToAllSidesOf(view: footer)

        Analytics.track(.incomingShareListShown)
    }

    // MARK: - UITableView methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        podcasts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: IncomingShareListViewController.cellId, for: indexPath) as! DiscoverPodcastTableCell
        cell.subscribeSource = analyticsSource

        let podcast = podcasts[indexPath.row]
        cell.populateFrom(podcast, number: -1)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let podcast = podcasts[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) as! DiscoverPodcastTableCell
        showPodcast(podcast, placeholderImage: cell.podcastImage.image, isFeatured: false)

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: Main actions

    @objc func doneTapped() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func subscribeToAllTapped(_ sender: AnyObject) {
        if podcasts.count > 2 {
            let optionPicker = OptionsPicker(title: nil)

            let subscribeAction = OptionAction(label: L10n.sharedListSubscribeConfAction, icon: nil, action: { [weak self] in
                self?.performSubscribeAll()
            })
            optionPicker.addDescriptiveActions(title: L10n.sharedListSubscribeConfTitle,
                                               message: L10n.sharedListSubscribeConfMsg(podcasts.count.localized()),
                                               icon: "option-podcasts",
                                               actions: [subscribeAction])

            optionPicker.show(statusBarStyle: preferredStatusBarStyle)
        } else {
            performSubscribeAll()
        }
    }

    func showPodcast(_ podcast: DiscoverPodcast, placeholderImage: UIImage?, isFeatured: Bool) {
        var podcastInfo = PodcastInfo()
        podcastInfo.populateFrom(discoverPodcast: podcast)
        let podcastViewController = PodcastViewController(podcastInfo: podcastInfo, existingImage: placeholderImage)
        podcastViewController.featuredPodcast = isFeatured
        navigationController?.pushViewController(podcastViewController, animated: true)
    }

    private func performSubscribeAll() {
        Analytics.track(.incomingShareListSubscribedAll, properties: ["count": podcasts.count])

        let loadingAlert = ShiftyLoadingAlert(title: L10n.shareListSubscribing)
        loadingAlert.showAlert(navigationController!, hasProgress: false) {
            self.subscribeNext(loadingAlert: loadingAlert)
        }
    }

    private func subscribeNext(loadingAlert: ShiftyLoadingAlert) {
        if podcasts.count == 0 {
            DispatchQueue.main.async { () in
                loadingAlert.hideAlert(true)
                self.dismiss(animated: true, completion: nil)
            }

            return
        }

        let podcast = podcasts.removeFirst()

        guard let uuid = podcast.uuid else {
            subscribeNext(loadingAlert: loadingAlert)
            return
        }

        ServerPodcastManager.shared.subscribe(to: uuid, completion: { _ in
            Analytics.track(.podcastSubscribed, properties: ["source": self.analyticsSource, "uuid": uuid])
            self.subscribeNext(loadingAlert: loadingAlert)
        })
    }

    private func loadSharedPodcasts() {
        guard let url = URL(string: jsonLocation) else {
            handleLoadFailed()
            return
        }

        SharingServerHandler.shared.loadList(listUrl: url) { podcastList in
            DispatchQueue.main.async {
                guard let podcastList = podcastList else {
                    self.handleLoadFailed()

                    return
                }

                self.populateList(podcastList)
            }
        }
    }

    private func handleLoadFailed() {
        // TODO:
    }

    private func populateList(_ podcastList: SharingServerHandler.PodcastList) {
        listTitle.text = podcastList.title
        listDescription.text = podcastList.listDescription
        textViewHeightConstraint.isActive = (listDescription.text?.count ?? 0) == 0

        var loadedPodcasts = [DiscoverPodcast]()
        if let listPodcasts = podcastList.podcasts {
            for listPodcast in listPodcasts {
                var convertedPodcast = DiscoverPodcast()
                convertedPodcast.title = listPodcast.title
                convertedPodcast.author = listPodcast.author
                convertedPodcast.shortDescription = listPodcast.podcastDescription
                convertedPodcast.uuid = listPodcast.uuid
                if let iTunesId = listPodcast.iTunesId {
                    convertedPodcast.iTunesId = "\(iTunesId)"
                }

                loadedPodcasts.append(convertedPodcast)
            }
        }

        podcasts = loadedPodcasts
        podcastCount.text = L10n.podcastCount(podcasts.count)
        podcastsTable.reloadData()
    }
}

extension IncomingShareListViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .incomingShareList
    }
}
