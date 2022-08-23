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
        }
    }
    
    @IBOutlet var roundedBackgroundView: ThemeableView! {
        didSet {
            roundedBackgroundView.style = .playerContrast06
        }
    }
    
    @IBOutlet var progressView: UIView! {
        didSet {
            progressView.backgroundColor = AppTheme.colorForStyle(.playerContrast06, themeOverride: themeOverride).withAlphaComponent(0.1)
        }
    }
    
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var dateLabel: ThemeableLabel! {
        didSet {
            dateLabel.style = .playerContrast02
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
            timeRemainingLabel.style = .playerContrast03
        }
    }
    
    @IBOutlet var episodeTitle: ThemeableLabel! {
        didSet {
            episodeTitle.style = .playerContrast01
        }
    }
    
    @IBOutlet var disclosureImageView: UIImageView! {
        didSet {
            disclosureImageView.layer.cornerRadius = 12
            disclosureImageView.backgroundColor = ThemeColor.primaryInteractive02()
        }
    }
    
    @IBOutlet var playingAnimationView: NowPlayingAnimationView!
    
    @IBOutlet var progressViewWidthConstraint: NSLayoutConstraint!
    
    private var episode: BaseEpisode!
    
    override func awakeFromNib() {
        super.awakeFromNib()
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
            podcastImage.setPodcast(uuid: episode.podcastUuid, size: .list)
        }
        else if let episode = episode as? UserEpisode {
            podcastImage.setUserEpisode(uuid: episode.uuid, size: .list)
        }
        
        EpisodeDateHelper.setDate(episode: episode, on: dateLabel, tintColor: ThemeColor.playerContrast02(for: themeOverride))
        
        if let dateText = dateLabel.text {
            dateLabel.accessibilityLabel = L10n.Localizable.queueNowPlayingAccessibility(dateText)
        }
        progressUpdated(animated: false)
    }
    
    @objc func progressUpdated(animated: Bool = true) {
        layoutIfNeeded()
        
        let duration = episode.duration
        let currentTime = PlaybackManager.shared.currentTime()
        
        guard duration > 0, currentTime.isFinite else { return }
        
        let remaining = duration - currentTime
        timeRemainingLabel.text = L10n.Localizable.queueTimeRemaining(TimeFormatter.shared.multipleUnitFormattedShortTime(time: remaining))
        
        let percentageLapsed = CGFloat(currentTime / duration)
        progressViewWidthConstraint.constant = percentageLapsed * roundedBackgroundView.frame.width
        
        playingAnimationView.animating = PlaybackManager.shared.playing()
        
        updateDownloadStatus()

        if animated {
            UIView.animate(withDuration: 0.95) {
                self.layoutIfNeeded()
            }
        }
        else { layoutIfNeeded() }
    }
    
    @objc func updatePlayingAnimation() {
        playingAnimationView.animating = PlaybackManager.shared.playing()
    }
    
    override func prepareForReuse() {
        progressViewWidthConstraint.constant = 0
        playingAnimationView.animating = false
    }
    
    override func handleThemeDidChange() {
        disclosureImageView.backgroundColor = ThemeColor.primaryInteractive02()
        progressView.backgroundColor = AppTheme.colorForStyle(.playerContrast06, themeOverride: themeOverride).withAlphaComponent(0.1)
    }

    func updateDownloadStatus() {
        if let episode = episode as? UserEpisode, episode.uploadStatus == UploadStatus.missing.rawValue {
            downloadingIndicator.isHidden = true
            downloadedIndicator.isHidden = true

            return
        }

        if episode.queued() {
            downloadingIndicator.stopAnimating()
            downloadingIndicator.isHidden = true
            downloadedIndicator.isHidden = true
        }
        else if episode.downloading() {
            if !downloadingIndicator.isAnimating {
                downloadingIndicator.startAnimating()
                downloadingIndicator.isHidden = false
                downloadedIndicator.isHidden = true
            }
        }
        else if episode.downloaded(pathFinder: DownloadManager.shared) {
            downloadingIndicator.stopAnimating()
            downloadingIndicator.isHidden = true
            downloadedIndicator.isHidden = false
        }
        else {
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
