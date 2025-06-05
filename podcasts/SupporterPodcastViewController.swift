import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class SupporterPodcastViewController: PCViewController, UITableViewDataSource, UITableViewDelegate {
    static let actionCellId = "AccountActionCellId"
    static let lastCellId = "LastSupporterPodcastCellId"
    private static let podcastCellId = "PodcastCell"
    @IBOutlet var tableView: ThemeableTable! {
        didSet {
            tableView.applyInsetForMiniPlayer()
            tableView.register(UINib(nibName: "AccountActionCell", bundle: nil), forCellReuseIdentifier: SupporterPodcastViewController.actionCellId)
            tableView.register(UINib(nibName: "LastSupporterPodcastCell", bundle: nil), forCellReuseIdentifier: SupporterPodcastViewController.lastCellId)
            tableView.register(UINib(nibName: "BundlePodcastCell", bundle: nil), forCellReuseIdentifier: SupporterPodcastViewController.podcastCellId)
            tableView.themeStyle = .primaryUi04
        }
    }

    @IBOutlet var headerView: UIView!

    @IBOutlet var bundleArtwork: BundleImageView! {
        didSet {
            bundleArtwork.layer.cornerRadius = 4
        }
    }

    @IBOutlet var bundleTitleLabel: ThemeableLabel! {
        didSet {
            bundleTitleLabel.style = .contrast01
        }
    }

    @IBOutlet var bundleLabel: ThemeableLabel! {
        didSet {
            bundleLabel.style = .contrast02
        }
    }

    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var nextPaymentLabel: ThemeableLabel! {
        didSet {
            nextPaymentLabel.style = .contrast02
        }
    }

    @IBOutlet var frequencyLabel: ThemeableLabel! {
        didSet {
            frequencyLabel.style = .contrast01
        }
    }

    @IBOutlet var cancelledLabel: ThemeableLabel! {
        didSet {
            cancelledLabel.style = .support05
        }
    }

    @IBOutlet var expiryLabel: ThemeableLabel! {
        didSet {
            expiryLabel.style = .contrast01
        }
    }

    @IBOutlet var supportHeartView: PodcastHeartView!

    @IBOutlet var cancelledOverlay: UIView!
    @IBOutlet var footerView: ThemeableView! {
        didSet {
            footerView.style = .primaryUi04
        }
    }

    @IBOutlet var footerBorderView: ThemeableView! {
        didSet {
            footerBorderView.style = .primaryUi06
            footerBorderView.layer.cornerRadius = 8
            footerBorderView.layer.borderWidth = 1
            footerBorderView.layer.borderColor = AppTheme.colorForStyle(.primaryUi05).cgColor
        }
    }

    @IBOutlet var footerHeartImage: UIImageView! {
        didSet {
            footerHeartImage.tintColor = AppTheme.colorForStyle(.primaryUi05Selected)
        }
    }

    @IBOutlet var cancelDetailsLabel: ThemeableLabel! {
        didSet {
            cancelDetailsLabel.style = .primaryText02
        }
    }

    var bundleCollection: PodcastCollection?
    var bundleSubscription: BundleSubscription
    var firstPodcastSubscription: PodcastSubscription?
    var podcasts = [Podcast]()
    init(bundleSubscription: BundleSubscription, bundleCollection: PodcastCollection? = nil) {
        self.bundleSubscription = bundleSubscription
        self.bundleCollection = bundleCollection
        firstPodcastSubscription = bundleSubscription.podcasts.first
        super.init(nibName: "SupporterPodcastViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Contribution Details"

        populateHeader()
        tableView.tableHeaderView = headerView

        if let firstPodcastSubscription = firstPodcastSubscription, firstPodcastSubscription.autoRenewing, firstPodcastSubscription.platformIsWeb() {
            tableView.tableFooterView = footerView
        }

        addCustomObserver(Constants.Notifications.podcastColorsDownloaded, selector: #selector(podcastColorsLoaded(_:)))
        addCustomObserver(Constants.Notifications.podcastAdded, selector: #selector(handlePodcastUpdate))
        addCustomObserver(Constants.Notifications.podcastDeleted, selector: #selector(handlePodcastUpdate))
        reloadRequired = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if reloadRequired {
            tableView.reloadData()
        }
    }

    private func isSingleBundleSubscription() -> Bool {
        bundleSubscription.podcasts.count == 1
    }

    enum TableRow { case goToPodcast, lastSupporterPodcast, cancelSubscription, bundlePodcast }
    private enum TableSection { case bundlePodcasts, manageSubscription }
    var tableData: [[TableRow]] = [[]]

    private func tableSections() -> [TableSection] {
        var sections = [TableSection]()
        if isSingleBundleSubscription() {
            sections.append(.manageSubscription)
        } else if !isSingleBundleSubscription(), let firstPodcastSubscription = firstPodcastSubscription, firstPodcastSubscription.autoRenewing, firstPodcastSubscription.platformIsWeb() {
            sections.append(.manageSubscription)
        }

        if !isSingleBundleSubscription() {
            sections.insert(.bundlePodcasts, at: 0)
        }

        return sections
    }

    private func rows(_ section: TableSection) -> [TableRow] {
        guard let firstPodcastSubscription = firstPodcastSubscription else {
            return [TableRow]()
        }

        switch section {
        case .manageSubscription:
            var rowData = [TableRow]()
            if firstPodcastSubscription.autoRenewing, firstPodcastSubscription.platformIsWeb() {
                rowData.append(.cancelSubscription)
            }

            if isSingleBundleSubscription() {
                rowData.append(.goToPodcast)
            }

            if SubscriptionHelper.hasActiveSubscription(), !firstPodcastSubscription.autoRenewing, firstPodcastSubscription.isPlusActivator {
                rowData.insert(.lastSupporterPodcast, at: rowData.count - 1)
            }
            return rowData
        case .bundlePodcasts:
            return [TableRow](repeating: .bundlePodcast, count: bundleSubscription.podcasts.count)
        }
    }

    // MARK: UITableView Delegate

    func numberOfSections(in tableView: UITableView) -> Int {
        tableSections().count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows(tableSections()[section]).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows(tableSections()[indexPath.section])[indexPath.row]

        switch row {
        case .goToPodcast:
            let cell = tableView.dequeueReusableCell(withIdentifier: SupporterPodcastViewController.actionCellId, for: indexPath) as! AccountActionCell
            cell.cellLabel.text = L10n.goToPodcast
            cell.cellImage.image = UIImage(named: "goto")
            cell.iconStyle = .primaryInteractive01
            cell.counterView.isHidden = true
            cell.iconStyle = .primaryIcon01
            return cell
        case .cancelSubscription:
            let cell = tableView.dequeueReusableCell(withIdentifier: SupporterPodcastViewController.actionCellId, for: indexPath) as! AccountActionCell
            cell.cellLabel.text = L10n.paidPodcastCancel
            cell.cellImage.image = UIImage(named: "cancelsubscription")
            cell.iconStyle = .primaryInteractive01
            cell.counterView.isHidden = true
            cell.iconStyle = .primaryIcon01
            return cell
        case .lastSupporterPodcast:
            let cell = tableView.dequeueReusableCell(withIdentifier: SupporterPodcastViewController.lastCellId, for: indexPath) as! LastSupporterPodcastCell
            return cell

        case .bundlePodcast:
            let cell = tableView.dequeueReusableCell(withIdentifier: SupporterPodcastViewController.podcastCellId, for: indexPath) as! BundlePodcastCell
            if var discoverPodcast = bundleCollection?.podcasts?[indexPath.row], let masterUuid = discoverPodcast.uuid, let userUuid = userUuidForMasterUuid(masterUuid) {
                discoverPodcast.uuid = userUuid
                cell.populateFrom(discoverPodcast, showDisclosure: firstPodcastSubscription?.isExpired() ?? false)
            }

            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows(tableSections()[indexPath.section])[indexPath.row]

        switch row {
        case .goToPodcast, .cancelSubscription:
            return 64
        case .lastSupporterPodcast:
            return 144
        case .bundlePodcast:
            return 72
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = rows(tableSections()[indexPath.section])[indexPath.row]
        switch row {
        case .goToPodcast:
            if let podcastUserUuid = bundleSubscription.podcasts.first?.uuid {
                NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcastUserUuid])
            }
        case .cancelSubscription:
            showCancelPrompt()
        case .lastSupporterPodcast:
            break
        case .bundlePodcast:
            reloadRequired = true
            let podcastUserUuid = bundleSubscription.podcasts[indexPath.row].uuid
            NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcastUserUuid])
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = tableSections()[section]
        switch section {
        case .bundlePodcasts:
            let headerFrame = CGRect(x: 0, y: 0, width: 0, height: 54)
            if let firstPodcastSubscription = firstPodcastSubscription, !firstPodcastSubscription.isExpired() {
                let podcastCount = bundleSubscription.podcasts.count.localized()
                let subscribedPodcastCount = bundleSubscription.podcasts.filter { DataManager.sharedManager.findPodcast(uuid: $0.uuid) != nil }.count.localized()
                let title = L10n.paidPodcastBundledSubscriptions(subscribedPodcastCount, podcastCount)
                let rightBtnTitle = subscribedPodcastCount == podcastCount ? L10n.unsubscribeAll.localizedUppercase : L10n.subscribeAll.localizedUppercase
                let rightBtnStyle: ThemeStyle = subscribedPodcastCount == podcastCount ? .support05 : .primaryInteractive01
                let rightBtnSelector = subscribedPodcastCount == podcastCount ? #selector(unsubscribeWarning) : #selector(subscribeAll)
                return SettingsTableHeader(frame: headerFrame, title: title, rightBtnTitle: rightBtnTitle, rightBtnSelector: rightBtnSelector, rightBtnTarget: self, rightBtnThemeStyle: rightBtnStyle)
            } else {
                return SettingsTableHeader(frame: headerFrame, title: L10n.podcastsPlural.localizedUppercase)
            }
        case .manageSubscription:
            let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)

            return SettingsTableHeader(frame: headerFrame, title: L10n.settings.localizedUppercase)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let thisSection = tableSections()[section]
        if thisSection == .bundlePodcasts {
            return 54
        } else if thisSection == .manageSubscription, !isSingleBundleSubscription() {
            return 40
        }
        return UITableView.automaticDimension
    }

    override func handleThemeChanged() {
        updateColors()
    }

    // MARK: - Private helpers

    private func showCancelPrompt() {
        guard let firstPodcastSubscription = bundleSubscription.podcasts.first, let firstPodcast = DataManager.sharedManager.findPodcast(uuid: firstPodcastSubscription.uuid, includeUnsubscribed: true) else { return }
        let actionSheet = OptionsPicker(title: nil)

        let cancelAction = OptionAction(label: L10n.paidPodcastCancel, icon: nil) { [weak self] in
            self?.performCancel()
        }
        cancelAction.destructive = true

        let expiryDateStr = DateFormatHelper.sharedHelper.longLocalizedFormat(Date(timeIntervalSince1970: TimeInterval(firstPodcastSubscription.expiryDate)))
        let deleteAfterExpiryMessage = isSingleBundleSubscription() ? L10n.paidPodcastCancelMsgSingular(expiryDateStr) : L10n.paidPodcastCancelMsgPlural(expiryDateStr)
        let message = firstPodcast.licensing == PodcastLicensing.deleteEpisodesAfterExpiry.rawValue ? deleteAfterExpiryMessage : L10n.paidPodcastCancelMsgRetainAccess(expiryDateStr)
        actionSheet.addDescriptiveActions(title: L10n.areYouSure, message: message, icon: "cancelsubscription-large", actions: [cancelAction])

        actionSheet.show(statusBarStyle: preferredStatusBarStyle)
    }

    private var progressAlert: ShiftyLoadingAlert?
    private func performCancel() {
        guard let firstPodcastSubscription = bundleSubscription.podcasts.first else { return }
        progressAlert = ShiftyLoadingAlert(title: L10n.canceling)
        progressAlert?.showAlert(self, hasProgress: false, completion: nil)
        ApiServerHandler.shared.cancelPaidPodcastSubcription(bundleUuid: firstPodcastSubscription.bundleUuid) { [weak self] success in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.progressAlert?.hideAlert(true)

                if success {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    SJUIUtils.showAlert(title: L10n.cancelFailed, message: L10n.pleaseTryAgainLater, from: self)
                }
            }
        }
    }

    private func populateHeader() {
        if isSingleBundleSubscription(), let uuid = bundleSubscription.podcasts.first?.uuid, let singlePodcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) {
            bundleTitleLabel.text = singlePodcast.title
            authorLabel.text = singlePodcast.author

            bundleArtwork.setPodcast(uuid: singlePodcast.uuid, size: .grid)
            bundleLabel.isHidden = true
        } else if let bundleInfo = bundleCollection {
            bundleTitleLabel.text = bundleInfo.title?.localized
            authorLabel.text = bundleInfo.author
            if let imageUrl = bundleInfo.collectionImage {
                bundleArtwork.setBundleImageUrl(url: imageUrl, size: .grid)
            }
            bundleLabel.isHidden = false
        } else {
            loadBundleCollection(uuid: bundleSubscription.bundleUuid)
        }
        updateColors()
        guard let firstPodcastSubscription = bundleSubscription.podcasts.first else {
            nextPaymentLabel.isHidden = true
            frequencyLabel.isHidden = true
            cancelledLabel.isHidden = true
            expiryLabel.isHidden = true
            cancelledOverlay.isHidden = true
            return
        }
        if firstPodcastSubscription.autoRenewing {
            cancelledLabel.isHidden = true
            cancelledOverlay.isHidden = true
            expiryLabel.isHidden = true
            frequencyLabel.isHidden = false
            nextPaymentLabel.isHidden = false
            frequencyLabel.text = SubscriptionHelper.readableSubscriptionFrequency(frequency: firstPodcastSubscription.frequency)

            let expiryDateStr = DateFormatHelper.sharedHelper.longLocalizedFormat(Date(timeIntervalSince1970: TimeInterval(firstPodcastSubscription.expiryDate)))
            nextPaymentLabel.text = L10n.nextPaymentFormat(expiryDateStr)
        } else {
            nextPaymentLabel.isHidden = true
            frequencyLabel.isHidden = true
            cancelledLabel.isHidden = false
            cancelledOverlay.isHidden = false

            if let firstPodcast = DataManager.sharedManager.findPodcast(uuid: firstPodcastSubscription.uuid, includeUnsubscribed: true) {
                expiryLabel.isHidden = false
                let expiryDate = Date(timeIntervalSince1970: firstPodcastSubscription.expiryDate)
                expiryLabel.text = firstPodcast.displayableExpiryLanguage(expiryDate: expiryDate)
            }
        }
    }

    // MARK: - Colors

    private func updateColors() {
        if isSingleBundleSubscription(), let podcastUuid = bundleSubscription.podcasts.first?.uuid {
            updatePodcastColors(podcastUuid)
        } else {
            updateBundleColors()
        }

        footerHeartImage.tintColor = ThemeColor.primaryUi05Selected()
        footerBorderView.layer.borderColor = ThemeColor.primaryUi05().cgColor
    }

    private func updateBundleColors() {
        guard let onLightColor = bundleCollection?.colors?.onLightBackground, let onDarkColor = bundleCollection?.colors?.onDarkBackground else {
            return
        }
        supportHeartView.setGradientColors(light: UIColor(hex: onLightColor), dark: UIColor(hex: onDarkColor))

        authorLabel.textColor = ThemeColor.contrast03()
        headerView.backgroundColor = ThemeColor.podcastUi03(podcastColor: UIColor(hex: onDarkColor))
    }

    private func updatePodcastColors(_ uuid: String) {
        guard let podcast = DataManager.sharedManager.findPodcast(uuid: uuid) else {
            return
        }
        supportHeartView.setPodcastColor(podcast: podcast)
        let podcastDarkColor = ColorManager.darkThemeTintForPodcast(podcast, defaultColor: AppTheme.extraContentBorderColor())
        authorLabel.textColor = ThemeColor.podcastText02(podcastColor: podcastDarkColor)
        let podcastBgColor = ColorManager.backgroundColorForPodcast(podcast)
        headerView.backgroundColor = ThemeColor.podcastUi03(podcastColor: podcastBgColor)
    }

    @objc private func podcastColorsLoaded(_ notification: Notification) {
        guard let uuidLoaded = notification.object as? String, isSingleBundleSubscription()
        else { return }

        if uuidLoaded == bundleCollection?.podcasts?.first?.uuid {
            updatePodcastColors(uuidLoaded)
        }
    }

    // MARK: - Helper functions

    var reloadRequired = false
    @objc func handlePodcastUpdate() {
        reloadRequired = true
    }

    @objc func subscribeAll() {
        bundleSubscription.podcasts.forEach { bundlePodcast in
            if !subscribe(uuid: bundlePodcast.uuid) {
                ServerPodcastManager.shared.addFromUuid(podcastUuid: bundlePodcast.uuid, subscribe: true) { [weak self] added in
                    guard let strongSelf = self, added else { return }
                    if added {
                        DispatchQueue.main.sync {
                            strongSelf.tableView.reloadData()
                        }
                    }
                }
            }
        }
        tableView.reloadData()
    }

    private func subscribe(uuid: String) -> Bool {
        guard let podcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) else {
            return false
        }
        podcast.subscribed = 1
        podcast.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(podcast: podcast)
        return true
    }

    @objc func unsubscribeWarning() {
        let optionPicker = OptionsPicker(title: nil)
        let unsubscribeAction = OptionAction(label: L10n.unsubscribeAll, icon: nil, action: { [weak self] in
            self?.unsubscribeAll()
        })

        unsubscribeAction.destructive = true
        optionPicker.addDescriptiveActions(title: L10n.unsubscribe, message: L10n.paidPodcastUnsubscribeMsg, icon: "option-alert", actions: [unsubscribeAction])

        optionPicker.show(statusBarStyle: preferredStatusBarStyle)
    }

    private func unsubscribeAll() {
        bundleSubscription.podcasts.forEach { bundlePodcast in
            if let podcast = DataManager.sharedManager.findPodcast(uuid: bundlePodcast.uuid) {
                PodcastManager.shared.unsubscribe(podcast: podcast)
            }
        }
        tableView.reloadData()
    }

    private func userUuidForMasterUuid(_ masterUuid: String) -> String? {
        guard let podcastPair = bundleSubscription.podcasts.first(where: { $0.masterUuid == masterUuid }) else {
            return nil
        }
        return podcastPair.uuid
    }

    private func loadBundleCollection(uuid: String) {
        let bundleUrl = ServerHelper.bundleUrl(bundleUuid: uuid)
        DiscoverServerHandler.shared.discoverPodcastCollection(source: bundleUrl.absoluteString, authenticated: nil, completion: { podcastCollection in
            guard let podcastCollection = podcastCollection else { return }
            self.bundleCollection = podcastCollection
            DispatchQueue.main.async {
                self.populateHeader()
                self.tableView.reloadData()
            }
        })
    }
}
