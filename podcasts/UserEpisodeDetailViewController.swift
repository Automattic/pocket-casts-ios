import PocketCastsDataModel
import PocketCastsServer
import UIKit

protocol UserEpisodeDetailProtocol: AnyObject {
    func showEdit(userEpisode: UserEpisode)
    func showDeleteConfirmation(userEpisode: UserEpisode)
    func showUpgradeRequired()
    func userEpisodeDetailClosed()
    func showBookmarks(userEpisode: UserEpisode)
}

class UserEpisodeDetailViewController: UIViewController {
    @IBOutlet var containerView: ThemeableView! {
        didSet {
            containerView.style = .primaryUi01
            containerView.layer.cornerRadius = 8
        }
    }

    @IBOutlet var titleLabel: ThemeableLabel! {
        didSet {
            titleLabel.style = .primaryText01
        }
    }

    @IBOutlet var imageView: PodcastImageView!

    @IBOutlet var infoLabel: ThemeableLabel! {
        didSet {
            infoLabel.style = .primaryText02
        }
    }

    @IBOutlet var downloadingIndicator: UIActivityIndicatorView!
    @IBOutlet var downloadStatusImage: UIImageView!

    @IBOutlet var upNextStatusImage: UIImageView!
    @IBOutlet var dividerView: ThemeableView! {
        didSet {
            dividerView.style = .primaryUi05
        }
    }

    @IBOutlet var playPauseButton: PlayPauseButton!

    @IBOutlet var containerViewHeight: NSLayoutConstraint!
    @IBOutlet var containerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var actionTable: ThemeableTable! {
        didSet {
            actionTable.themeStyle = .primaryUi01
        }
    }

    @IBOutlet var greyBackgroundView: UIView!
    @IBOutlet var barView: ThemeableView! {
        didSet {
            barView.style = .primaryUi05
            barView.layer.cornerRadius = 4
        }
    }

    @IBOutlet var errorContainerView: ThemeableSelectionView! {
        didSet {
            errorContainerView.unselectedStyle = .primaryUi05
            errorContainerView.style = .primaryUi06
            errorContainerView.layer.cornerRadius = 8
            errorContainerView.layer.borderWidth = 1
        }
    }

    @IBOutlet var errorExclaimationImageView: UIImageView!
    @IBOutlet var errorStatusImage: UIImageView!
    @IBOutlet var errorTypeLabel: ThemeableLabel!
    @IBOutlet var errorMessageLabel: ThemeableLabel! {
        didSet {
            errorMessageLabel.style = .primaryText02
        }
    }

    @IBOutlet var containerViewToErrorViewConstraint: NSLayoutConstraint!
    @IBOutlet var containerViewToImageViewConstraint: NSLayoutConstraint!

    @IBOutlet var uploadStatusImage: UIImageView!
    @IBOutlet var uploadProgressIndicator: ProgressPieView!
    var episode: UserEpisode
    weak var delegate: UserEpisodeDetailProtocol?

    var themeOverride: Theme.ThemeType?

    var playlist: AutoplayHelper.Playlist?

    private var window: UIWindow?
    private static let containerHeightWithError: CGFloat = 534
    private static let containerHeightWithoutError: CGFloat = 430

    enum TableRow { case download, bookmarks, removeFromCloud, upload, upNext, markAsPlayed, editDetails, delete, cancelUpload, cancelDownload }
    let actionCellId = "UserEpisodeActionCell"

    // MARK: - Init

    init(episodeUuid: String) {
        episode = DataManager.sharedManager.findUserEpisode(uuid: episodeUuid)! // TODO: consider making this optional
        super.init(nibName: "UserEpisodeDetailViewController", bundle: nil)
    }

    @objc init(episode: UserEpisode) {
        self.episode = episode

        super.init(nibName: "UserEpisodeDetailViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    private var hasError = false
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = episode.title
        imageView.setUserEpisode(uuid: episode.uuid, size: .list)
        downloadStatusImage.image = UIImage(named: "episode-downloaded")
        registerCells()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hide))
        greyBackgroundView.addGestureRecognizer(tapGesture)
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(hide))
        swipeDown.direction = .down
        containerView.addGestureRecognizer(swipeDown)

        playPauseButton.isPlaying = PlaybackManager.shared.isActivelyPlaying(episodeUuid: episode.uuid)

        actionTable.backgroundColor = UIColor.clear
        greyBackgroundView.backgroundColor = UIColor.clear

        hasError = episode.playbackError() || episode.uploadFailed() || episode.downloadFailed()
        errorContainerView.isHidden = !hasError
        containerViewHeight.constant = hasError ? UserEpisodeDetailViewController.containerHeightWithError : UserEpisodeDetailViewController.containerHeightWithoutError
        containerViewBottomConstraint.constant = -containerViewHeight.constant
        updateStatus()
        Analytics.track(.userFileDetailShown)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if PlaybackManager.shared.currentEpisode() != nil {
            actionTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Constants.Values.miniPlayerOffset, right: 0)
        } else {
            actionTable.contentInset = UIEdgeInsets.zero
        }
        view.layoutIfNeeded()

        updateColors()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addObservers()
    }

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateFromNotification), name: Constants.Notifications.episodeDownloaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFromNotification), name: Constants.Notifications.episodeDownloadStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFromNotification), name: ServerNotifications.userEpisodeUploadStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFromNotification), name: Constants.Notifications.episodePlayStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUploadProgress), name: ServerNotifications.userEpisodeUploadProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDownloadProgress), name: Constants.Notifications.downloadProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeChanged), name: Constants.Notifications.themeChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleThemeChanged() {
        updateColors()
    }

    @objc private func updateFromNotification() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let oldEpisode = self.episode

            self.reloadEpisode()
            self.updateStatus()

            if oldEpisode.uploadStatus != self.episode.uploadStatus || oldEpisode.episodeStatus != self.episode.episodeStatus {
                self.actionTable.reloadData()
            }
        }
    }

    private func reloadEpisode() {
        guard let reloadedEpisode = DataManager.sharedManager.findUserEpisode(uuid: episode.uuid) else {
            return // episode no longer exists so nothing to reload
        }

        episode = reloadedEpisode
        let newHasError = episode.playbackError() || episode.uploadFailed() || episode.downloadFailed()
        if !hasError, newHasError, !isAnimatingOut, !isAnimatingIn {
            hasError = newHasError
            animateInError()
        } else if hasError, !newHasError, !isAnimatingOut, !isAnimatingIn {
            hasError = newHasError
            animateOutError()
        }
    }

    private func updateColors() {
        titleLabel.themeOverride = themeOverride
        containerView.themeOverride = themeOverride
        infoLabel.themeOverride = themeOverride
        dividerView.themeOverride = themeOverride
        actionTable.themeOverride = themeOverride
        errorTypeLabel.themeOverride = themeOverride
        errorMessageLabel.themeOverride = themeOverride
        errorContainerView.themeOverride = themeOverride

        playPauseButton.circleColor = ThemeColor.primaryIcon01(for: themeOverride)
        playPauseButton.playButtonColor = ThemeColor.primaryUi01(for: themeOverride)

        downloadStatusImage.tintColor = AppTheme.successGreen()
        upNextStatusImage.tintColor = ThemeColor.primaryIcon01(for: themeOverride)
    }

    private func updateStatus() {
        upNextStatusImage.isHidden = !PlaybackManager.shared.inUpNext(episode: episode)

        errorStatusImage.isHidden = !hasError
        infoLabel.text = hasError ? episode.displayableDuration(includeSize: true) : episode.displayableInfo(includeSize: true)

        if hasError {
            if episode.downloadFailed() {
                errorTypeLabel.text = L10n.playerUserEpisodeDownloadError
                errorMessageLabel.text = episode.downloadErrorDetails
            } else if episode.playbackError() {
                errorTypeLabel.text = L10n.playerUserEpisodePlaybackError
                errorMessageLabel.text = episode.playbackErrorDetails
            } else if episode.uploadFailed() {
                errorTypeLabel.text = L10n.playerUserEpisodeUploadError
                errorMessageLabel.text = L10n.pleaseTryAgain
            }
        }

        downloadStatusImage.isHidden = !episode.downloaded(pathFinder: DownloadManager.shared)
        uploadStatusImage.isHidden = !episode.uploaded()

        uploadProgressIndicator.isHidden = !episode.uploading()
        downloadingIndicator.isHidden = !episode.downloading()

        updateUploadProgress()
        updateDownloadProgress()
    }

    @objc private func updateUploadProgress() {
        guard UploadManager.shared.progressManager.hasProgressForUserEpisode(episode.uuid) else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if !self.episode.uploading() {
                self.reloadEpisode()
            }

            self.uploadProgressIndicator.isHidden = !self.episode.uploading()
            if self.episode.uploading() {
                self.infoLabel.text = self.episode.displayableInfo(includeSize: true)
                if let progress = UploadManager.shared.progressManager.progressForEpisode(self.episode.uuid) {
                    self.uploadProgressIndicator.progress = progress.percentageProgress()
                } else {
                    self.uploadProgressIndicator.progress = 0
                }
            }
        }
    }

    @objc func updateDownloadProgress() {
        guard let _ = DownloadManager.shared.progressManager.progressForEpisode(episode.uuid) else { return }

        if !episode.downloading() {
            reloadEpisode()
        }

        if episode.downloading() {
            infoLabel.text = episode.displayableInfo(includeSize: true)
        }

        if episode.downloading(), !downloadingIndicator.isAnimating {
            downloadingIndicator.isHidden = false
            downloadingIndicator.startAnimating()
        } else if !episode.downloading(), downloadingIndicator.isAnimating {
            downloadingIndicator.stopAnimating()
        }
    }

    // MARK: Actions

    @objc func hide() {
        Analytics.track(.userFileDetailDismissed)
        animateOut()
    }

    // MARK: - Animate in/out

    private var isAnimatingIn = true
    private var isAnimatingOut = false
    func animateIn() {
        window = SceneHelper.newMainScreenWindow()
        guard let window = window else { return }

        window.rootViewController = self
        window.windowLevel = UIWindow.Level.alert
        window.makeKeyAndVisible()

        containerViewBottomConstraint.constant = -containerHeight()
        view.layoutIfNeeded()
        UIView.animate(withDuration: Constants.Animation.bottomCardAnimationTime, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            guard let self = self else { return }

            self.containerViewBottomConstraint.constant = 0
            self.greyBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)

            self.view.layoutIfNeeded()
        }) { [weak self] _ in
            self?.containerViewBottomConstraint.constant = 0
            self?.view.layoutIfNeeded()
            self?.isAnimatingIn = false
        }
    }

    func animateOut() {
        isAnimatingOut = true
        view?.layoutIfNeeded()
        UIView.animate(withDuration: Constants.Animation.bottomCardAnimationTime, animations: { [weak self] in
            guard let self = self else { return }

            self.greyBackgroundView.backgroundColor = UIColor.clear
            self.containerViewBottomConstraint.constant = -self.containerHeight()
            self.view.layoutIfNeeded()
        }) { [weak self] _ in
            self?.delegate?.userEpisodeDetailClosed()
            self?.window?.resignKey()
            self?.window = nil
        }
    }

    func animateInError() {
        errorContainerView.alpha = 0
        errorContainerView.isHidden = false

        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime / 2, animations: { [weak self] in
            guard let self = self else { return }
            self.containerViewHeight.constant = UserEpisodeDetailViewController.containerHeightWithError
            self.view.layoutIfNeeded()
        }) { [weak self] _ in
            self?.containerViewHeight.constant = UserEpisodeDetailViewController.containerHeightWithError
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime / 2, animations: { [weak self] in
                guard let self = self else { return }
                self.errorContainerView.alpha = 1
            }) { [weak self] _ in
                self?.errorContainerView.alpha = 1
                self?.containerViewHeight.constant = UserEpisodeDetailViewController.containerHeightWithError
            }
        }
    }

    func animateOutError() {
        errorContainerView.alpha = 1
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime / 2, animations: { [weak self] in
            guard let self = self else { return }
            self.errorContainerView.alpha = 0
        }) { [weak self] _ in

            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime / 2, animations: { [weak self] in
                guard let self = self else { return }
                self.containerViewHeight.constant = UserEpisodeDetailViewController.containerHeightWithoutError
                self.view.layoutIfNeeded()

            }) { [weak self] _ in
                self?.errorContainerView.alpha = 0
                self?.errorContainerView.isHidden = true
                self?.containerViewHeight.constant = UserEpisodeDetailViewController.containerHeightWithoutError
            }
        }
    }

    private func containerHeight() -> CGFloat {
        containerViewHeight?.constant ?? 500
    }

    @objc private func backgroundTapped() {
        animateOut()
    }
}

extension UserEpisodeDetailViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource { .userEpisode }
}
