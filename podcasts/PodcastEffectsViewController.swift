import PocketCastsDataModel
import UIKit
import PocketCastsUtils

class PodcastLocalEffectsProvider {
    private(set) var effects: PlaybackEffects

    private let playbackManager: PlaybackManager = .shared

    init(podcast: Podcast) {
        if podcast.overrideGlobalEffects, !podcast.usedCustomEffectsBefore {
            podcast.usedCustomEffectsBefore = true
            DataManager.sharedManager.save(podcast: podcast)
        }
        self.effects = playbackManager.effectsFor(podcast: podcast)
    }

    func update(podcast: Podcast) {
        effects = playbackManager.effectsFor(podcast: podcast)
    }

    func applyLocalEffets(for podcast: Podcast) {
        PlaybackManager.shared.changeLocalEffects(effects, for: podcast)
    }

    func applyLocalEffetsAndSave(for podcast: Podcast) {
        applyLocalEffets(for: podcast)

        DataManager.sharedManager.save(podcast: podcast)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast.uuid)

        // if we're actively playing this episode, let the player know
        if let episode = PlaybackManager.shared.currentEpisode() as? Episode, podcast.uuid == episode.parentIdentifier() {
            PlaybackManager.shared.effectsChangedExternally()
        }
    }
}

class PodcastEffectsViewController: PCViewController {
    @IBOutlet var effectsTable: UITableView! {
        didSet {
            registerCells()
        }
    }

    var playbackSpeedDebouncer: Debounce = .init(delay: 1)

    var podcast: Podcast
    var localEffectsProvider: PodcastLocalEffectsProvider?

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

        if FeatureFlag.customPlaybackSettings.enabled {
            localEffectsProvider = PodcastLocalEffectsProvider(podcast: podcast)
        }
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if FeatureFlag.customPlaybackSettings.enabled {
            localEffectsProvider?.applyLocalEffetsAndSave(for: podcast)
            return
        }
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
                localEffectsProvider?.update(podcast: updatedPodcast)
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
