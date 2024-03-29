import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class UpNextNowPlayingCell: ThemeableCell {
    override var themeOverride: Theme.ThemeType? {
        didSet {
            super.updateColor()
            episodeTitle.themeOverride = themeOverride
            dateLabel.themeOverride = themeOverride
            timeRemainingLabel.themeOverride = themeOverride
            roundedBackgroundView.themeOverride = themeOverride
        }
    }

    @IBOutlet var roundedBackgroundView: ThemeableView!

    @IBOutlet var progressView: UIView!

    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var dateLabel: ThemeableLabel! {
        didSet {
            dateLabel.style = .primaryText02
        }
    }

    @IBOutlet var downloadedIndicator: UIImageView!
    @IBOutlet var downloadingIndicator: UIActivityIndicatorView! {
        didSet {
            downloadingIndicator.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        }
    }

    @IBOutlet var timeRemainingLabel: ThemeableLabel! {
        didSet {
            timeRemainingLabel.style = .primaryText02
        }
    }

    @IBOutlet var episodeTitle: ThemeableLabel! {
        didSet {
            episodeTitle.style = .primaryText01
        }
    }

    @IBOutlet var disclosureImageView: UIImageView!

    @IBOutlet var playingAnimationView: NowPlayingAnimationView!

    @IBOutlet var progressViewWidthConstraint: NSLayoutConstraint!

    private var episode: BaseEpisode? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        style = .primaryUi04

        NotificationCenter.default.addObserver(self, selector: #selector(progressUpdated), name: Constants.Notifications.playbackProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayingAnimation), name: Constants.Notifications.playbackPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayingAnimation), name: Constants.Notifications.playbackStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellForDownloadProgressChange), name: Constants.Notifications.downloadProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellForDownloadStatusChange(_:)), name: Constants.Notifications.episodeDownloaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellForDownloadStatusChange(_:)), name: Constants.Notifications.episodeDownloadStatusChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func populateFrom(episode: BaseEpisode) {
        self.episode = DataManager.sharedManager.findBaseEpisode(uuid: episode.uuid) // this is a bit hacky, but we're likely to be passed the cached version here from the player, so reload it from the database to get the latest version with the correct download stats

        episodeTitle.text = episode.displayableTitle()

        if let episode = episode as? Episode {
            podcastImage.setEpisode(episode, size: .list)
        } else if let episode = episode as? UserEpisode {
            podcastImage.setUserEpisode(uuid: episode.uuid, size: .list)
        }

        EpisodeDateHelper.setDate(episode: episode, on: dateLabel, tintColor: ThemeColor.primaryText02(for: themeOverride))

        if let dateText = dateLabel.text {
            dateLabel.accessibilityLabel = L10n.queueNowPlayingAccessibility(dateText)
        }
        progressUpdated(animated: false)
    }

    @objc func progressUpdated(animated: Bool = true) {
        layoutIfNeeded()

        let duration: Double
        let currentTime: TimeInterval

        if let episode = episode {
            duration = episode.duration
            currentTime = PlaybackManager.shared.currentTime()
        }
        else {
            duration = 1
            currentTime = 1
        }

        guard duration > 0, currentTime.isFinite else { return }

        let remaining = duration - currentTime
        timeRemainingLabel.text = L10n.queueTimeRemaining(TimeFormatter.shared.multipleUnitFormattedShortTime(time: remaining))

        let percentageLapsed = CGFloat(currentTime / duration)
        progressViewWidthConstraint.constant = percentageLapsed * roundedBackgroundView.frame.width

        playingAnimationView.animating = PlaybackManager.shared.playing()

        updateDownloadStatus()

        if animated {
            UIView.animate(withDuration: 0.95) {
                self.layoutIfNeeded()
            }
        } else { layoutIfNeeded() }
    }

    @objc func updatePlayingAnimation() {
        playingAnimationView.animating = PlaybackManager.shared.playing()
    }

    override func prepareForReuse() {
        progressViewWidthConstraint.constant = 0
        playingAnimationView.animating = false
    }

    override func handleThemeDidChange() {
        super.handleThemeDidChange()

        let activeTheme = themeOverride ?? Theme.sharedTheme.activeTheme

        // Rounded background
        if activeTheme.isDark {
            roundedBackgroundView.style = .playerContrast06
        } else {
            roundedBackgroundView.style = activeTheme == .contrastLight ? .primaryUi05 : .primaryUi02
        }

        // Progress view
        if activeTheme == .rosé {
            progressView.backgroundColor = AppTheme.colorForStyle(.primaryIcon02Selected, themeOverride: themeOverride).withAlphaComponent(0.1)
        } else if activeTheme.isDark {
            progressView.backgroundColor = AppTheme.colorForStyle(.playerContrast06, themeOverride: themeOverride).withAlphaComponent(0.1)
        } else {
            progressView.backgroundColor = .black.withAlphaComponent(0.1)
        }

        // Disclosure icon
        switch activeTheme {
        case .dark:
            disclosureImageView.backgroundColor = AppTheme.colorForStyle(.primaryInteractive02)
            disclosureImageView.tintColor = nil

        case .contrastLight, .contrastDark:
            disclosureImageView.backgroundColor = AppTheme.colorForStyle(.primaryInteractive01, themeOverride: themeOverride)
            disclosureImageView.tintColor = AppTheme.colorForStyle(.primaryInteractive02, themeOverride: themeOverride)

        default:
            disclosureImageView.backgroundColor = AppTheme.colorForStyle(.primaryUi05, themeOverride: themeOverride)
            disclosureImageView.tintColor = AppTheme.colorForStyle(.primaryInteractive01, themeOverride: themeOverride)
        }

        disclosureImageView.layer.cornerRadius = 12
    }

    func updateDownloadStatus() {
        guard let episode = episode else {
            downloadingIndicator.isHidden = true
            downloadedIndicator.isHidden = true
            return
        }
        if let episode = episode as? UserEpisode, episode.uploadStatus == UploadStatus.missing.rawValue {
            downloadingIndicator.isHidden = true
            downloadedIndicator.isHidden = true

            return
        }

        if episode.queued() {
            downloadingIndicator.stopAnimating()
            downloadingIndicator.isHidden = true
            downloadedIndicator.isHidden = true
        } else if episode.downloading() {
            if !downloadingIndicator.isAnimating {
                downloadingIndicator.startAnimating()
                downloadingIndicator.isHidden = false
                downloadedIndicator.isHidden = true
            }
        } else if episode.downloaded(pathFinder: DownloadManager.shared) {
            downloadingIndicator.stopAnimating()
            downloadingIndicator.isHidden = true
            downloadedIndicator.isHidden = false
        } else {
            downloadingIndicator.isHidden = true
            downloadedIndicator.isHidden = true
        }
    }

    @objc private func updateCellForDownloadProgressChange() {
        guard let ourEpisode = episode, let _ = DownloadManager.shared.progressManager.progressForEpisode(ourEpisode.uuid) else { return }

        if !ourEpisode.downloading() {
            episode = DataManager.sharedManager.findBaseEpisode(uuid: ourEpisode.uuid)
        }

        updateDownloadStatus()
    }

    @objc private func updateCellForDownloadStatusChange(_ notification: Notification) {
        // make sure this event is related to our episode
        guard let ourEpisode = episode, let uuid = notification.object as? String, ourEpisode.uuid == uuid else { return }

        // if it is, reload our episode so we get the latest status for it
        episode = DataManager.sharedManager.findBaseEpisode(uuid: ourEpisode.uuid)

        updateDownloadStatus()
    }
}
