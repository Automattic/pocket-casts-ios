import Combine
import Foundation
import PocketCastsServer
import UIKit

class SingleEpisodeViewController: UIViewController {
    private let viewModel = DiscoverEpisodeViewModel()
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet var episodeTitle: ThemeableLabel!
    @IBOutlet var podcastTitle: ThemeableLabel! {
        didSet {
            podcastTitle.style = .primaryText02
        }
    }

    @IBOutlet var playButton: PlayPauseLabeledButton!
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var typeBadgeLabel: UILabel!

    @IBOutlet var duration: ThemeableLabel! {
        didSet {
            duration.text = L10n.unknownDuration
            duration.style = .primaryText02
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        (view as? ThemeableView)?.style = .primaryUi02
        view.translatesAutoresizingMaskIntoConstraints = false

        observeEpisodeChanges()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didSelectEpisode))
        view.addGestureRecognizer(tapGesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.registerListImpression()
    }

    func observeEpisodeChanges() {
        viewModel.$title
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] title in
                self.episodeTitle.text = title
            })
            .store(in: &cancellables)

        viewModel.$imageUUID
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] uuid in
                if let uuid = uuid {
                    self.podcastImage.setPodcast(uuid: uuid, size: .grid)
                }
            })
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.$episodeDuration, viewModel.$publishedDate)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] episodeDuration, publishedDate in
                self.duration.text = [episodeDuration, publishedDate].compactMap { $0 }.joined(separator: " • ")
            })
            .store(in: &cancellables)

        viewModel.$podcastTitle
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] title in
                self.podcastTitle.text = title
            })
            .store(in: &cancellables)

        viewModel.$isTrailer
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] isTrailer in
                self.playButton.text = isTrailer ? L10n.discoverPlayTrailer : L10n.discoverPlayEpisode
            })
            .store(in: &cancellables)

        viewModel.$episodeUUID
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] episodeUUID in
                self.playButton.episodeUUID = episodeUUID
            })
            .store(in: &cancellables)

        Publishers.CombineLatest(Theme.sharedTheme.$activeTheme, viewModel.$discoverCollection)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] _, discoverCollection in
                self.playButton.colors = discoverCollection?.colors
                self.typeBadgeLabel.textColor = discoverCollection?.colors?.activeThemeColor ?? AppTheme.colorForStyle(.support02)
            })
            .store(in: &cancellables)
    }

    @IBAction func didSelectPlay(_ sender: Any) {
        playButton.isPlaying = !playButton.isPlaying
        viewModel.didSelectPlayEpisode(from: playButton)
    }

    @objc func didSelectEpisode(_ sender: Any) {
        viewModel.didSelectEpisode()
    }
}

extension SingleEpisodeViewController: DiscoverSummaryProtocol {
    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        viewModel.delegate = delegate
    }

    func populateFrom(item: DiscoverItem, region: String?) {
        viewModel.discoverItem = item

        typeBadgeLabel.text = (item.title ?? L10n.discoverFeaturedEpisode).uppercased()
    }
}
