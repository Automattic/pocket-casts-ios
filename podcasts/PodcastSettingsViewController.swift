import DifferenceKit
import PocketCastsDataModel
import UIKit

class PodcastSettingsViewController: PCViewController {
    var podcast: Podcast
    var episodes = [ArraySection<String, ListItem>]()

    let debounce = Debounce(delay: Constants.defaultDebounceTime)

    enum TableRow { case autoDownload, notifications, upNext, globalUpNext, upNextPosition, playbackEffects, skipFirst, skipLast, autoArchive, inFilters, siriShortcut, unsubscribe, feedError }

    var existingShortcut: Any?

    @IBOutlet var settingsTable: UITableView! {
        didSet {
            registerCells()
        }
    }

    init(podcast: Podcast) {
        self.podcast = podcast
        super.init(nibName: "PodcastSettingsViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateExistingSortcutData()
        title = L10n.settingsTitle

        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: settingsTable)

        NotificationCenter.default.addObserver(self, selector: #selector(podcastUpdated(_:)), name: Constants.Notifications.podcastUpdated, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        changeNavTint(titleColor: nil, iconsColor: podcast.navIconTintColor(), backgroundColor: podcast.navigationBarTintColor())
        settingsTable.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addCustomObserver(Constants.Notifications.podcastColorsDownloaded, selector: #selector(colorsDidDownload))
        settingsTable.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        removeAllCustomObservers()
    }

    override func handleThemeChanged() {
        updateColors()
    }

    @objc private func colorsDidDownload(_ notification: Notification) {
        guard let uuidLoaded = notification.object as? String else { return }

        if podcast.uuid == uuidLoaded {
            if let updatedPodcast = DataManager.sharedManager.findPodcast(uuid: podcast.uuid) {
                podcast = updatedPodcast
                updateColors()
            }
        }
    }

    private func updateColors() {
        changeNavTint(titleColor: nil, iconsColor: podcast.navIconTintColor(), backgroundColor: podcast.navigationBarTintColor())
        settingsTable.reloadData()
    }

    func updateExistingSortcutData() {
        SiriShortcutsManager.shared.voiceShortcutForPodcast(podcast: podcast, completion: { voiceShortcut in
            self.existingShortcut = voiceShortcut
            DispatchQueue.main.async {
                self.settingsTable.reloadData()
            }
        })
    }

    func unsubscribe() {
        var downloadedCount = 0

        for object in episodes[1].elements {
            guard let listEpisode = object as? ListEpisode else { continue }

            if listEpisode.episode.episodeStatus == DownloadStatus.downloaded.rawValue {
                downloadedCount += 1
            }
        }
        let optionPicker = OptionsPicker(title: downloadedCount > 0 ? nil : L10n.areYouSure)
        let unsubscribeAction = OptionAction(label: L10n.unsubscribe, icon: nil, action: { [weak self] in
            self?.performUnsubscribe()
        })
        if downloadedCount > 0 {
            unsubscribeAction.destructive = true
            optionPicker.addDescriptiveActions(title: L10n.downloadedFilesConf(downloadedCount), message: L10n.downloadedFilesConfMessage, icon: "option-alert", actions: [unsubscribeAction])
        } else {
            optionPicker.addAction(action: unsubscribeAction)
        }
        optionPicker.show(statusBarStyle: preferredStatusBarStyle)
    }

    private func performUnsubscribe() {
        PodcastManager.shared.unsubscribe(podcast: podcast)
        navigationController?.popToRootViewController(animated: true)
        Analytics.track(.podcastUnsubscribed, properties: ["source": analyticsSource, "uuid": podcast.uuid])
    }

    @objc func podcastUpdated(_ notification: Notification) {
        guard let podcastUuid = notification.object as? String, podcastUuid == podcast.uuid, let updatedPodcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid) else { return }

        podcast = updatedPodcast
    }
}

extension PodcastSettingsViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .podcastSettings
    }
}
