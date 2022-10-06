import PocketCastsDataModel
import UIKit

class PodcastEffectsViewController: PCViewController {
    @IBOutlet var effectsTable: UITableView! {
        didSet {
            registerCells()
        }
    }

    var playbackSpeedDebouncer: Debounce = .init(delay: 1)

    var podcast: Podcast

    init(podcast: Podcast) {
        self.podcast = podcast
        super.init(nibName: "PodcastEffectsViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = PlayerAction.effects.title()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        changeNavTint(titleColor: nil, iconsColor: podcast.navIconTintColor(), backgroundColor: podcast.navigationBarTintColor())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addCustomObserver(Constants.Notifications.podcastColorsDownloaded, selector: #selector(podcastUpdated(_:)))
        addCustomObserver(Constants.Notifications.podcastUpdated, selector: #selector(podcastUpdated(_:)))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        removeAllCustomObservers()
    }

    override func handleThemeChanged() {
        updateColors()
    }

    @objc private func podcastUpdated(_ notification: Notification) {
        guard let uuidLoaded = notification.object as? String else { return }

        if podcast.uuid == uuidLoaded {
            if let updatedPodcast = DataManager.sharedManager.findPodcast(uuid: podcast.uuid) {
                podcast = updatedPodcast
                updateColors()
                effectsTable.reloadData()
            }
        }
    }

    private func updateColors() {
        changeNavTint(titleColor: nil, iconsColor: podcast.navIconTintColor(), backgroundColor: podcast.navigationBarTintColor())
        effectsTable.reloadData()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        UIStatusBarStyle.lightContent
    }
}

extension PodcastEffectsViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .podcastSettings
    }
}
