import PocketCastsDataModel
import SwipeCellKit
import UIKit

class PlayerCell: SwipeTableViewCell {
    var themeOverride: Theme.ThemeType? {
        didSet {
            updateColor()
            episodeTitle.themeOverride = themeOverride
            episodeInfo.themeOverride = themeOverride
            dayName.themeOverride = themeOverride
        }
    }
    
    var style: ThemeStyle = .primaryUi02 {
        didSet {
            updateColor()
        }
    }
    
    var selectedStyle: ThemeStyle = .primaryUi02Active
    var iconStyle: ThemeStyle = .primaryIcon02
    
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var episodeTitle: ThemeableLabel! {
        didSet {
            episodeTitle.style = .playerContrast01
        }
    }
    
    @IBOutlet var episodeInfo: ThemeableLabel! {
        didSet {
            episodeInfo.style = .playerContrast03
        }
    }
    
    @IBOutlet var downloadedIndicator: UIImageView!
    @IBOutlet var dayName: ThemeableLabel! {
        didSet {
            dayName.style = .playerContrast03
        }
    }
    
    @IBOutlet var downloadingIndicator: UIActivityIndicatorView! {
        didSet {
            downloadingIndicator.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        }
    }
    
    @IBOutlet var selectView: UIView! {
        didSet {
            selectView.layer.borderColor = AppTheme.colorForStyle(.playerContrast01, themeOverride: themeOverride).cgColor
            selectView.layer.borderWidth = 0
            selectView.layer.cornerRadius = 12
        }
    }
    
    @IBOutlet var dividerView: ThemeableView! {
        didSet {
            dividerView.style = .playerContrast05
            dividerView.themeOverride = themeOverride
        }
    }
    
    @IBOutlet var podcastImageToSelectViewConstraint: NSLayoutConstraint!
    @IBOutlet var selectViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var selectTickImageView: UIImageView!
    
    var showTick = false {
        didSet {
            selectTickImageView.isHidden = !showTick
            selectView.backgroundColor = showTick ? AppTheme.colorForStyle(.playerContrast01, themeOverride: themeOverride) : AppTheme.colorForStyle(.primaryUi04, themeOverride: themeOverride)
            selectTickImageView.tintColor = AppTheme.colorForStyle(.primaryUi04, themeOverride: themeOverride)
            
            selectView.accessibilityLabel = showTick ? L10n.accessibilityDeselectEpisode : L10n.accessibilitySelectEpisode
        }
    }
    
    private var episode: BaseEpisode!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellForDownloadProgressChange), name: Constants.Notifications.downloadProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellForDownloadStatusChange(_:)), name: Constants.Notifications.episodeDownloaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellForDownloadStatusChange(_:)), name: Constants.Notifications.episodeDownloadStatusChanged, object: nil)
    
        overrideUserInterfaceStyle = .dark
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func populateFrom(episode: BaseEpisode) {
        self.episode = episode

        episodeTitle.text = episode.displayableTitle()
        if let episode = episode as? Episode {
            podcastImage.setPodcast(uuid: episode.podcastUuid, size: .list)
        }
        else if let episode = episode as? UserEpisode {
            podcastImage.setUserEpisode(uuid: episode.uuid, size: .list)
        }
        updateDownloadStatus()
        
        EpisodeDateHelper.setDate(episode: episode, on: dayName, tintColor: ThemeColor.primaryText01(for: themeOverride))
        
        accessibilityLabel = labelForAccessibility(episode: episode)
    }
    
    private func labelForAccessibility(episode: BaseEpisode?) -> String {
        guard let episode = episode else { return "" }
        let heading = dayName.text?.replacingOccurrences(of: "•", with: ",") ?? ""
        let title = episodeTitle.text ?? ""
        let subtitle = episode.subTitle()
        let info = episodeInfo.text ?? ""

        var desc = [heading, subtitle, title, info]
        if episode.downloaded(pathFinder: DownloadManager.shared) {
            desc.append(L10n.statusDownloaded)
        }
        else if let playbackError = episode.playbackErrorDetails {
            desc.append(playbackError)
        }

        return desc.joined(separator: ". ")
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
    
    func updateDownloadStatus() {
        if let episode = episode as? UserEpisode, episode.uploadStatus == UploadStatus.missing.rawValue {
            episodeInfo.text = L10n.downloadErrorNotUploaded
            downloadingIndicator.isHidden = true
            downloadedIndicator.isHidden = true
            
            return
        }
        
        if episode.queued() {
            downloadingIndicator.stopAnimating()
            downloadingIndicator.isHidden = true
            downloadedIndicator.isHidden = true
            episodeInfo.text = episode.displayableInfo(includeSize: Settings.primaryRowAction() == .download)
        }
        else if episode.downloading() {
            if !downloadingIndicator.isAnimating {
                downloadingIndicator.startAnimating()
                downloadingIndicator.isHidden = false
                downloadedIndicator.isHidden = true
            }
            episodeInfo.text = episode.displayableInfo(includeSize: Settings.primaryRowAction() == .download)
        }
        else if episode.downloaded(pathFinder: DownloadManager.shared) {
            downloadingIndicator.stopAnimating()
            downloadingIndicator.isHidden = true
            downloadedIndicator.isHidden = false
            episodeInfo.text = episode.displayableTimeLeft()
        }
        else {
            downloadingIndicator.isHidden = true
            downloadedIndicator.isHidden = true
            episodeInfo.text = episode.displayableTimeLeft()
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        setHighlightedState(highlighted)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        setHighlightedState(selected)
    }
    
    private func setHighlightedState(_ highlighted: Bool) {
        if highlighted {
            updateBgColor(AppTheme.colorForStyle(selectedStyle, themeOverride: themeOverride))
        }
        else {
            updateBgColor(AppTheme.colorForStyle(style, themeOverride: themeOverride))
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        // Show the reordering control but not the native selection view (editControl)
        // In iOS13+ the tableView is in editing mode but the cell is not
        super.setEditing(false, animated: animated)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        showTick = false
        setSelected(false, animated: false)
    }
    
    func updateColor() {
        updateBgColor(AppTheme.colorForStyle(style, themeOverride: themeOverride))
        accessoryView?.tintColor = AppTheme.colorForStyle(iconStyle, themeOverride: themeOverride)
        tintColor = AppTheme.colorForStyle(iconStyle, themeOverride: themeOverride)
    }
    
    private func updateBgColor(_ color: UIColor) {
        contentView.backgroundColor = color
        backgroundColor = color
        accessoryView?.backgroundColor = color
    }
    
    func shouldShowSelect(show: Bool, animate: Bool) {
        if animate {
            if show {
                selectView.layer.borderWidth = 2
                hideSwipe(animated: true)
            }
            contentView.layoutIfNeeded()
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
                self.selectViewLeadingConstraint.constant = show ? 20 : -24
                self.contentView.layoutIfNeeded()
            }, completion: { _ in
                if !show {
                    self.showTick = false
                    self.selectView.layer.borderWidth = 0
                    self.setHighlightedState(false)
                }
            })
        }
        else {
            selectViewLeadingConstraint.constant = show ? 20 : -24
            showTick = false
            selectView.layer.borderWidth = show ? 2 : 0
            if !show {
                setHighlightedState(false)
            }
        }
    }
}
