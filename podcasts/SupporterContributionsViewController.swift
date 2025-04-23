import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class SupporterContributionsViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    static let supporterCellId = "PodcastSupporterCellId"
    @IBOutlet var tableView: ThemeableTable! {
        didSet {
            tableView.applyInsetForMiniPlayer()
            tableView.register(UINib(nibName: "PodcastSupporterCell", bundle: nil), forCellReuseIdentifier: SupporterContributionsViewController.supporterCellId)
            tableView.themeStyle = .primaryUi02
        }
    }

    private var bundleSubscriptions: [BundleSubscription]?
    var bundleInfo = [String: PodcastCollection]()
    var podcasts = [String: Podcast]()
    var bundleUuidToOpen: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.supporterContributions
        bundleSubscriptions = SubscriptionHelper.subscriptionBundles()
        loadBundles()
        addCustomObserver(Constants.Notifications.podcastColorsDownloaded, selector: #selector(podcastColorsLoaded(_:)))
        addCustomObserver(ServerNotifications.subscriptionStatusChanged, selector: #selector(handleSubscriptionsUpdated))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let bundleUuid = bundleUuidToOpen, let bundle = bundleSubscriptions?.first(where: { $0.bundleUuid == bundleUuid }) {
            bundleUuidToOpen = nil
            showBundleDetails(bundle: bundle)
        }
    }

    // MARK: Tableivew source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bundleSubscriptions?.count ?? 0
    }

    // MARK: Tableview delegate

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SupporterContributionsViewController.supporterCellId, for: indexPath) as! PodcastSupporterCell

        guard let bundleUuid = bundleSubscriptions?[indexPath.row].bundleUuid, let bundle = bundleInfo[bundleUuid] else {
            cell.isLoading = true
            cell.heartView.setGradientColors(light: AppTheme.podcastHeartLightRedGradientColor(), dark: AppTheme.podcastHeartDarkRedGradientColor())

            return cell
        }

        if bundle.podcasts?.count == 1 {
            guard let subscription = bundleSubscriptions?[indexPath.row].podcasts.first, subscription.uuid.count > 0 else {
                cell.isLoading = true
                cell.heartView.setGradientColors(light: AppTheme.podcastHeartLightRedGradientColor(), dark: AppTheme.podcastHeartDarkRedGradientColor())

                return cell
            }

            let uuid = subscription.uuid
            cell.podcastArtwork.setPodcast(uuid: uuid, size: .list)

            guard let podcast = podcasts[uuid] else {
                cell.isLoading = true
                cell.heartView.setGradientColors(light: AppTheme.podcastHeartLightRedGradientColor(), dark: AppTheme.podcastHeartDarkRedGradientColor())

                return cell
            }

            cell.isLoading = false
            cell.podcastName.text = podcast.title
            cell.podcastName.sizeToFit()

            cell.authorLabel.text = podcast.author
            cell.heartView.setPodcastColor(podcast: podcast)
            cell.heartView.isHidden = true
        } else {
            cell.isLoading = false
            cell.podcastName.text = bundle.title?.localized
            cell.podcastName.sizeToFit()
            cell.authorLabel.text = bundle.author
            cell.heartView.setBundleCount(bundle.podcasts?.count ?? 0)
            if let colors = bundle.colors, let darkColor = colors.onDarkBackground, let lightColor = colors.onLightBackground {
                cell.heartView.setGradientColors(light: UIColor(hex: lightColor), dark: UIColor(hex: darkColor))
            }
            if let collageUrl = bundle.collectionImage {
                cell.podcastArtwork.setBundleImageUrl(url: collageUrl, size: .list)
            }
        }

        // Set the subscription frequency based on the first
        // podcast subscription in the bundle
        var frequencyText = ""
        var isCancelled = false
        if let firstPodcastUuid = bundleSubscriptions?[indexPath.row].podcasts.first?.uuid, let subscription = SubscriptionHelper.subscriptionForPodcast(uuid: firstPodcastUuid) {
            let expiryDate = Date(timeIntervalSince1970: subscription.expiryDate)

            if subscription.autoRenewing {
                isCancelled = false
                let frequency = subscription.frequency
                frequencyText = SubscriptionHelper.readableSubscriptionFrequency(frequency: frequency).localizedUppercase
            } else {
                isCancelled = true
                let expiryDateStr = DateFormatHelper.sharedHelper.longLocalizedFormat(expiryDate).localizedUppercase
                if expiryDate.timeIntervalSinceNow < 0 {
                    frequencyText = L10n.paidPodcastSubscriptionEnded(expiryDateStr)
                } else {
                    frequencyText = L10n.paidPodcastSubscriptionEnds(expiryDateStr)
                }
            }

            if expiryDate.timeIntervalSinceNow > 0, bundle.podcasts?.count == 1 {
                cell.heartView.isHidden = false
            }
        }

        cell.bundleLabel.isHidden = !(!isCancelled && bundle.podcasts?.count ?? 0 > 1)
        cell.dotLabel.isHidden = cell.bundleLabel.isHidden
        cell.cancelledLabel.isHidden = !isCancelled
        cell.frequencyLabel.isHidden = false
        cell.frequencyLabel.text = frequencyText

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let selectedBundle = bundleSubscriptions?[indexPath.row] else { return }
        showBundleDetails(bundle: selectedBundle)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }

    // MARK: Helpers

    private func showBundleDetails(bundle: BundleSubscription) {
        let bundleCollection = bundleInfo[bundle.bundleUuid]
        let detailsVC = SupporterPodcastViewController(bundleSubscription: bundle, bundleCollection: bundleCollection)
        navigationController?.pushViewController(detailsVC, animated: true)
    }

    @objc private func handleSubscriptionsUpdated() {
        DispatchQueue.main.async {
            self.bundleSubscriptions = SubscriptionHelper.subscriptionBundles()
            self.loadPodcasts()
            self.tableView.reloadData()

            if let bundleUuid = self.bundleUuidToOpen, let bundle = self.bundleSubscriptions?.first(where: { $0.bundleUuid == bundleUuid }) {
                self.bundleUuidToOpen = nil
                self.showBundleDetails(bundle: bundle)
            }
        }
    }

    func loadBundles() {
        guard let bundles = bundleSubscriptions else { return }
        for bundle in bundles {
            let bundleUrl = ServerHelper.bundleUrl(bundleUuid: bundle.bundleUuid)
            DiscoverServerHandler.shared.discoverPodcastCollection(source: bundleUrl.absoluteString, authenticated: nil, completion: { podcastCollection in

                guard let podcastCollection = podcastCollection else { return }
                self.bundleInfo[bundle.bundleUuid] = podcastCollection
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
        }
        loadPodcasts()
    }

    func loadPodcasts() {
        guard let bundles = bundleSubscriptions else {
            return
        }
        var subscriptions = [PodcastSubscription]()
        bundles.forEach { subscriptions.append(contentsOf: $0.podcasts) }

        podcasts.removeAll()
        for subscribedPodcast in subscriptions {
            if !loadPodcast(uuid: subscribedPodcast.uuid) {
                ServerPodcastManager.shared.addFromUuid(podcastUuid: subscribedPodcast.uuid, subscribe: false) { [weak self] added in
                    guard let strongSelf = self, added else { return }
                    if strongSelf.loadPodcast(uuid: subscribedPodcast.uuid) {
                        DispatchQueue.main.sync {
                            strongSelf.tableView.reloadData()
                        }
                    }
                }
            }
        }
        tableView.reloadData()
    }

    private func loadPodcast(uuid: String) -> Bool {
        if let podcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) {
            podcasts[uuid] = podcast
            return true
        }
        return false
    }

    @objc private func podcastColorsLoaded(_ notification: Notification) {
        loadPodcasts()
    }

    private func loadBundle(uuid: String) {}
}
