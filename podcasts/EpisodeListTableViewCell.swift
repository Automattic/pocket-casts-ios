import Combine
import PocketCastsServer
import UIKit

class EpisodeListTableViewCell: UITableViewCell {
    static let estimatedCellHeight: CGFloat = 147
    static let nib: UINib = .init(nibName: String(describing: EpisodeListTableViewCell.self), bundle: Bundle(for: EpisodeListTableViewCell.self))

    public let viewModel = DiscoverEpisodeViewModel()
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet var episodeTitle: ThemeableLabel!
    @IBOutlet var podcastTilte: UILabel!

    @IBOutlet var playButton: PlayPauseButton!
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var duration: UILabel! {
        didSet {
            duration.text = L10n.unknownDuration
        }
    }

    @IBOutlet var episodeInfo: ThemeableLabel! {
        didSet {
            episodeInfo.text = ""
            episodeInfo.style = .primaryText02
        }
    }

    var colors: PodcastCollectionColors? {
        didSet {
            updateTheme()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        observeEpisodeChanges()
        playButton.isPlaying = false
        observePlayStateChanges()

        Theme.sharedTheme.$activeTheme
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] _ in
                self.updateTheme()
            })
            .store(in: &cancellables)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        podcastImage.clearArtwork()
        playButton.isPlaying = false
        viewModel.discoverEpisode = nil
    }

    func observeEpisodeChanges() {
        viewModel.$title
            .sink(receiveValue: { [unowned self] title in
                self.episodeTitle.text = title
            })
            .store(in: &cancellables)

        viewModel.$imageUUID
            .sink(receiveValue: { [unowned self] uuid in
                if let uuid = uuid {
                    self.podcastImage.setPodcast(uuid: uuid, size: .grid)
                }
            })
            .store(in: &cancellables)

        viewModel.$episodeDuration
            .sink(receiveValue: { [unowned self] episodeDuration in
                self.duration.text = episodeDuration
                self.duration.isHidden = episodeDuration == nil
            })
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.$seasonInfo, viewModel.$publishedDate)
            .sink(receiveValue: { [unowned self] seasonInfo, publishedDate in
                self.episodeInfo.text = [seasonInfo, publishedDate].compactMap { $0 }.joined(separator: " • ")
            })
            .store(in: &cancellables)

        viewModel.$podcastTitle
            .sink(receiveValue: { [unowned self] title in
                self.podcastTilte.text = title
            })
            .store(in: &cancellables)

        viewModel.$episodeUUID
            .sink(receiveValue: { [unowned self] episodeUUID in
                self.updatePlayingState(forUUID: episodeUUID)
            })
            .store(in: &cancellables)
    }

    @IBAction func didSelectPlayButton(_ sender: Any) {
        viewModel.didSelectPlayEpisode(from: playButton)
    }

    private func updateTheme() {
        contentView.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
        playButton.playButtonColor = AppTheme.colorForStyle(.primaryUi01)

        let tintColor = colors?.activeThemeColor ?? AppTheme.colorForStyle(.support05)

        playButton.circleColor = tintColor
        podcastTilte.textColor = tintColor
        duration.textColor = tintColor
    }

    private func observePlayStateChanges() {
        Publishers.Merge3(
            NotificationCenter.default.publisher(for: Constants.Notifications.playbackStarted),
            NotificationCenter.default.publisher(for: Constants.Notifications.playbackPaused),
            NotificationCenter.default.publisher(for: Constants.Notifications.playbackEnded)
        )
        .receive(on: RunLoop.main)
        .sink { [unowned self] _ in
            self.updatePlayingState()
        }
        .store(in: &cancellables)
    }

    private func updatePlayingState(forUUID episodeUUID: String? = nil) {
        guard let episodeUUID = episodeUUID ?? viewModel.episodeUUID else {
            playButton.isPlaying = false
            return
        }
        playButton.isPlaying = PlaybackManager.shared.isActivelyPlaying(episodeUuid: episodeUUID)
    }
}
