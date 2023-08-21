import PocketCastsDataModel
import PocketCastsServer
import UIKit

class EpisodeCell: ThemeableSwipeCell, MainEpisodeActionViewDelegate {
    private static let playedAlpha: CGFloat = 0.5

    @IBOutlet var episodeImage: PodcastImageView!
    @IBOutlet var episodeTitle: ThemeableLabel!
    @IBOutlet var statusIndicator: UIImageView!
    @IBOutlet var uploadStatusIndicator: UIImageView!

    @IBOutlet var uploadProgressIndicator: ProgressPieView!
    @IBOutlet var upNextIndicator: UIImageView!

    @IBOutlet var leadingSpacerWidth: NSLayoutConstraint!
    @IBOutlet var selectTickHorizontalOffset: NSLayoutConstraint!
    @IBOutlet var selectCircleHorizontalOffset: NSLayoutConstraint!

    @IBOutlet var downloadingIndicator: UIActivityIndicatorView! {
        didSet {
            downloadingIndicator.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        }
    }
    @IBOutlet var bookmarkIcon: UIImageView!

    @IBOutlet var informationLabel: ThemeableLabel! {
        didSet {
            informationLabel.style = .primaryText02
            informationLabel.font = informationLabel.font.monospaced()
        }
    }

    @IBOutlet var bottomDivider: ThemeDividerView!
    @IBOutlet var bottomDividerHeightConstraint: NSLayoutConstraint! {
        didSet {
            bottomDividerHeightConstraint.constant = 1.0 / UIScreen.main.scale
        }
    }

    @IBOutlet var dayName: ThemeableLabel! {
        didSet {
            dayName.style = .primaryText02
        }
    }

    @IBOutlet var starIndicator: UIImageView! {
        didSet {
            starIndicator.image = UIImage(named: "list_starred")?.tintedImage(ThemeColor.support10())
        }
    }

    @IBOutlet var videoIndicator: UIImageView!
    @IBOutlet var actionButton: MainEpisodeActionView! {
        didSet {
            actionButton.bottomPadding = 5
            actionButton.delegate = self
        }
    }

    @IBOutlet var contentStackView: UIStackView!

    @IBOutlet var selectView: UIView!

    @IBOutlet var selectTickImageView: UIImageView! {
        didSet {
            selectTickImageView.backgroundColor = ThemeColor.primaryInteractive01()
            selectTickImageView.tintColor = ThemeColor.primaryInteractive02()
            selectTickImageView.layer.cornerRadius = 12
        }
    }

    @IBOutlet var selectCircleView: UIView! {
        didSet {
            selectCircleView.layer.borderColor = ThemeColor.primaryIcon02().cgColor
            selectCircleView.layer.borderWidth = 2
            selectCircleView.layer.cornerRadius = 12
        }
    }

    var hidesArtwork = false

    var playlist: AutoplayHelper.Playlist?

    private var inUpNext = false
    private var filterUuid: String?
    private var podcastUuid: String?
    private var listUuid: String?
    private var mainTintColor: UIColor? {
        didSet {
            actionButton.tintColor = mainTintColor
        }
    }

    private var episode: BaseEpisode?

    // MARK: - Setup

    override func awakeFromNib() {
        super.awakeFromNib()

        NotificationCenter.default.addObserver(self, selector: #selector(updateCellFromGenericEvent), name: Constants.Notifications.playbackStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellFromGenericEvent), name: Constants.Notifications.playbackEnded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellFromGenericEvent), name: Constants.Notifications.playbackPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellFromGenericEvent), name: Constants.Notifications.playbackFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellFromGenericEvent), name: Constants.Notifications.googleCastStatusChanged, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(downloadProgressDidUpdate), name: Constants.Notifications.downloadProgress, object: nil)

        // events that are specific to an episode
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellFromSpecificEvent(_:)), name: Constants.Notifications.episodeDurationChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellFromSpecificEvent(_:)), name: Constants.Notifications.episodeStarredChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellFromSpecificEvent(_:)), name: Constants.Notifications.episodeDownloadStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellFromSpecificEvent(_:)), name: ServerNotifications.episodeTypeOrLengthChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellFromSpecificEvent(_:)), name: Constants.Notifications.playbackPositionSaved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellFromSpecificEvent(_:)), name: Constants.Notifications.episodePlayStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellFromSpecificEvent(_:)), name: Constants.Notifications.episodeDownloaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellFromSpecificEvent(_:)), name: ServerNotifications.userEpisodeUploadStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(uploadProgressDidUpdate), name: ServerNotifications.userEpisodeUploadProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadArtwork(_:)), name: Constants.Notifications.userEpisodeUpdated, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}

    var isMultiSelectEnabled = false
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(false, animated: animated)
        isMultiSelectEnabled = editing

        shouldShowSelect = editing
        if editing {
            hideSwipe(animated: true)
        } else {
            showTick = false
        }
        accessibilityLabel = labelForAccessibility(episode: episode)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Workaround for iOS issue. When a table transitions to editing mode
        // it takes over hiding/showing views and sometimes the selectivew doesn't
        // appear.
        if selectView.isHidden == isMultiSelectEnabled {
            selectView.isHidden = !isMultiSelectEnabled
            setNeedsLayout()
        }
        if actionButton.isHidden == !isMultiSelectEnabled {
            actionButton.isHidden = isMultiSelectEnabled
            setNeedsLayout()
        }
    }

    // MARK: - Populate Method

    func populateFrom(episode: BaseEpisode, tintColor: UIColor?, filterUuid: String? = nil, podcastUuid: String? = nil, listUuid: String? = nil) {
        self.episode = episode
        self.filterUuid = filterUuid
        self.podcastUuid = podcastUuid
        self.listUuid = listUuid
        mainTintColor = tintColor ?? ThemeColor.primaryIcon01()

        populate(progressOnly: false)
    }

    private func populate(progressOnly: Bool) {
        guard let episode = episode else { return }

        if !progressOnly {
            setEpisodeTitle(episode: episode)

            starIndicator.isHidden = !episode.keepEpisode
            videoIndicator.isHidden = !episode.videoPodcast()
            videoIndicator.tintColor = ThemeColor.support01()
            upNextIndicator.isHidden = !PlaybackManager.shared.inUpNext(episode: episode)
            upNextIndicator.tintColor = ThemeColor.support01()

            let showBookmarksIcon = FeatureFlag.bookmarks.enabled && PaidFeature.bookmarks.isUnlocked
            if showBookmarksIcon {
                bookmarkIcon.image = UIImage(named: "bookmark-icon-episode")
                bookmarkIcon.tintColor = mainTintColor
                bookmarkIcon.isHidden = !episode.hasBookmarks
            } else {
                bookmarkIcon.isHidden = true
            }

            var uploadFailed = false
            if let userEpisode = episode as? UserEpisode {
                uploadStatusIndicator.isHidden = !userEpisode.uploaded()
                uploadFailed = userEpisode.uploadFailed()
            } else {
                uploadStatusIndicator.isHidden = true
            }

            let hideStatus = !episode.archived && !episode.downloaded(pathFinder: DownloadManager.shared) && !episode.downloadFailed() && !uploadFailed && !episode.playbackError()
            if !hideStatus {
                let statusImage: UIImage?
                if episode.downloadFailed() || uploadFailed || episode.playbackError() {
                    statusImage = UIImage(named: "list_downloadfailed")
                } else if episode.downloaded(pathFinder: DownloadManager.shared) {
                    statusImage = UIImage(named: "list_downloaded")
                } else {
                    if showBookmarksIcon {
                        statusImage = UIImage(named: "bookmark-icon-episode")?.tintedImage(mainTintColor ?? ThemeColor.primaryIcon02())
                        bookmarkIcon.image = UIImage(named: "list_archived")?.tintedImage(ThemeColor.primaryIcon02())
                    } else {
                        statusImage = UIImage(named: "list_archived")?.tintedImage(ThemeColor.primaryIcon02())
                    }
                }
                statusIndicator.image = statusImage
            }
            statusIndicator.isHidden = hideStatus

            if hidesArtwork {
                if !episodeImage.isHidden {
                    episodeImage.isHidden = true
                }
                leadingSpacerWidth.constant = 8
                selectTickHorizontalOffset.constant = 0
                selectCircleHorizontalOffset.constant = 0
            } else {
                leadingSpacerWidth.constant = 12
                selectTickHorizontalOffset.constant = 4
                selectCircleHorizontalOffset.constant = 4

                if let userEpisode = episode as? UserEpisode {
                    episodeImage.setUserEpisode(uuid: userEpisode.uuid, size: .list)
                } else {
                    episodeImage.setPodcast(uuid: episode.parentIdentifier(), size: .list)
                }
            }

            if episode.played() || episode.archived {
                episodeImage.alpha = EpisodeCell.playedAlpha
                contentStackView.alpha = EpisodeCell.playedAlpha
            } else {
                episodeImage.alpha = 1
                contentStackView.alpha = 1
            }
        }

        inUpNext = PlaybackManager.shared.inUpNext(episode: episode)

        EpisodeDateHelper.setDate(episode: episode, on: dayName, tintColor: mainTintColor)

        if episode.archived {
            informationLabel.text = L10n.podcastArchived + " • " + episode.displayableInfo(includeSize: false)
        } else if let userEpisode = episode as? UserEpisode {
            informationLabel.text = userEpisode.displayableInfo(includeSize: Settings.primaryRowAction() == .download)
        } else {
            informationLabel.text = episode.displayableInfo(includeSize: Settings.primaryRowAction() == .download)
        }

        if episode.downloading(), !downloadingIndicator.isAnimating {
            downloadingIndicator.startAnimating()
        } else if !episode.downloading(), downloadingIndicator.isAnimating {
            downloadingIndicator.stopAnimating()
        }

        if let userEpisode = episode as? UserEpisode {
            uploadProgressIndicator.isHidden = !(userEpisode.uploading() || userEpisode.uploadWaitingForWifi())
            if userEpisode.uploading() {
                if let progress = UploadManager.shared.progressManager.progressForEpisode(userEpisode.uuid) {
                    uploadProgressIndicator.progress = progress.percentageProgress()
                } else {
                    uploadProgressIndicator.progress = 0.1
                }
                uploadProgressIndicator.alpha = 1
            } else if userEpisode.uploadWaitingForWifi() {
                uploadProgressIndicator.progress = 0
                uploadProgressIndicator.alpha = 0.5
            }
        } else {
            uploadProgressIndicator.isHidden = true
        }

        actionButton.populateFrom(episode: episode)

        isAccessibilityElement = true
        accessibilityLabel = labelForAccessibility(episode: episode)
    }

    private func labelForAccessibility(episode: BaseEpisode?) -> String {
        guard let episode = episode else { return "" }
        let heading = dayName.text?.replacingOccurrences(of: "•", with: ",") ?? ""
        let title = episodeTitle.text ?? ""
        let info = informationLabel.text ?? ""

        var desc = [heading]

        // add the podcast name in place of the artwork, if it's showing
        if !hidesArtwork {
            desc.append(episode.subTitle())
        }

        desc.append(title)
        desc.append(info)

        if episode.downloaded(pathFinder: DownloadManager.shared) {
            desc.append(L10n.statusDownloaded)
        } else if episode.downloadFailed() {
            desc.append(episode.readableErrorMessage())
        } else if let playbackError = episode.playbackErrorDetails {
            desc.append(playbackError)
        }
        if episode.keepEpisode {
            desc.append(L10n.statusStarred)
        }
        if let userEpisode = episode as? UserEpisode, userEpisode.uploaded() {
            desc.append(L10n.statusUploaded)
        }
        if isMultiSelectEnabled {
            if showTick {
                desc.append(L10n.statusSelected)
            } else {
                desc.append(L10n.statusNotSelected)
            }
        }
        return desc.joined(separator: ". ")
    }

    private func setEpisodeTitle(episode: BaseEpisode) {
        guard let title = episode.title else {
            episodeTitle.text = nil

            return
        }

        // if there's no episode numbers make sure we still optimise the title
        if let episode = episode as? Episode, episode.episodeNumber < 1 {
            episodeTitle.text = episode.displayableTitle()

            return
        }

        episodeTitle.text = title
    }

    // MARK: - Event Handling

    @objc private func updateCellFromGenericEvent() {
        guard let episode = episode else { return }

        updateCell(episodeUuid: episode.uuid)
    }

    @objc private func updateCellFromSpecificEvent(_ notification: Notification) {
        guard let episodeUuid = notification.object as? String, episodeUuid == episode?.uuid else {
            return
        }

        updateCell(episodeUuid: episodeUuid)
    }

    private func updateCell(episodeUuid: String) {
        guard let newEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid) else { return }

        if Thread.isMainThread {
            populateFrom(episode: newEpisode, tintColor: mainTintColor, filterUuid: filterUuid, podcastUuid: podcastUuid)
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.populateFrom(episode: newEpisode, tintColor: self.mainTintColor, filterUuid: self.filterUuid, podcastUuid: self.podcastUuid)
            }
        }
    }

    @objc private func downloadProgressDidUpdate() {
        guard let ourEpisode = episode, let _ = DownloadManager.shared.progressManager.progressForEpisode(ourEpisode.uuid) else { return }

        // if this episode isn't listed as downloading, update it from the DB
        if !ourEpisode.downloading() {
            episode = reloadEpisode()
        }

        populate(progressOnly: true)
    }

    @objc private func uploadProgressDidUpdate() {
        guard let ourEpisode = episode as? UserEpisode, let _ = UploadManager.shared.progressManager.progressForEpisode(ourEpisode.uuid) else { return }

        // if this episode isn't listed as uploading, update it from the DB
        if !ourEpisode.uploading() {
            episode = reloadEpisode()
        }

        if Thread.isMainThread {
            populate(progressOnly: true)
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.populate(progressOnly: true)
            }
        }
    }

    @objc func reloadArtwork(_ notification: Notification) {
        guard let episodeUuid = notification.object as? String,
              episodeUuid == episode?.uuid,
              let userEpisode = episode as? UserEpisode else { return }
        episodeImage.setUserEpisode(uuid: userEpisode.uuid, size: .list)
    }

    // MARK: - MainEpisodeActionViewDelegate

    func downloadTapped() {
        guard let uuid = episode?.uuid else { return }

        PlaybackActionHelper.download(episodeUuid: uuid)
    }

    func stopDownloadTapped() {
        guard let uuid = episode?.uuid else { return }

        PlaybackActionHelper.stopDownload(episodeUuid: uuid)
    }

    func playTapped() {
        guard let episode = episode else { return }

        // if the user tapped play from a featured list, record that. We just want the first play, if they are unpausing it, that's not relevant (hence the last check below)
        if let podcastUuid = podcastUuid, let listUuid = listUuid, !PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) {
            AnalyticsHelper.podcastEpisodePlayedFromList(listId: listUuid, podcastUuid: podcastUuid)
        }

        PlaybackActionHelper.play(episode: episode, filterUuid: filterUuid, podcastUuid: podcastUuid, playlist: playlist)
    }

    func pauseTapped() {
        PlaybackActionHelper.pause()
    }

    func errorTapped() {
        guard let episode = episode else { return }

        let statusBarStyle = filterUuid == nil ? UIStatusBarStyle.lightContent : AppTheme.defaultStatusBarStyle()
        if episode.playbackError() {
            let optionsPicker = OptionsPicker(title: nil)
            let retryAction = OptionAction(label: L10n.retry, icon: nil, action: { [weak self] in
                self?.playTapped()
            })

            optionsPicker.addDescriptiveActions(title: L10n.playbackFailed, message: episode.playbackErrorDetails, icon: "option-alert", actions: [retryAction])
            optionsPicker.show(statusBarStyle: statusBarStyle)
        } else {
            let downloadError = episode.readableErrorMessage()
            let optionsPicker = OptionsPicker(title: nil)
            let retryAction = OptionAction(label: L10n.retry, icon: nil, action: { [weak self] in
                self?.downloadTapped()
            })
            optionsPicker.addDescriptiveActions(title: L10n.downloadFailed, message: downloadError, icon: "option-alert", actions: [retryAction])
            optionsPicker.show(statusBarStyle: statusBarStyle)
        }
    }

    func waitingForWifiTapped() {
        guard let uuid = episode?.uuid else { return }

        PlaybackActionHelper.overrideWaitingForWifi(episodeUuid: uuid, autoDownloadStatus: .autoDownloaded)
    }

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        false
    }

    private func reloadEpisode() -> BaseEpisode? {
        if let episode = episode as? Episode {
            return DataManager.sharedManager.findEpisode(uuid: episode.uuid)
        } else if let episode = episode as? UserEpisode {
            return DataManager.sharedManager.findUserEpisode(uuid: episode.uuid)
        }

        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        starIndicator.isHidden = true
        upNextIndicator.isHidden = true
        statusIndicator.isHidden = true
        uploadProgressIndicator.isHidden = true
        uploadStatusIndicator.isHidden = true
        filterUuid = nil
        podcastUuid = nil
        showTick = false
        shouldShowSelect = false
        actionButton.isHidden = false
    }

    // MARK: - Multi Select icons

    var shouldShowSelect = false {
        didSet {
            selectView.isHidden = !shouldShowSelect
            actionButton.isHidden = shouldShowSelect
        }
    }

    var showTick = false {
        didSet {
            selectTickImageView.isHidden = !showTick
            selectCircleView.layer.borderWidth = showTick ? 0 : 2
            selectView.accessibilityLabel = showTick ? L10n.accessibilityDeselectEpisode : L10n.accessibilitySelectEpisode
            accessibilityLabel = labelForAccessibility(episode: episode)
            style = showTick ? .primaryUi02Selected : .primaryUi02
            updateColor()
        }
    }

    // Handle theme change
    override func handleThemeDidChange() {
        selectCircleView.layer.borderColor = ThemeColor.primaryIcon02().cgColor
        selectTickImageView.backgroundColor = ThemeColor.primaryInteractive01()
        selectTickImageView.tintColor = ThemeColor.primaryInteractive02()
        starIndicator.image = UIImage(named: "list_starred")?.tintedImage(ThemeColor.support10())
    }
}
