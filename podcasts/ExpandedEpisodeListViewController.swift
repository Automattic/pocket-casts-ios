import Combine
import PocketCastsDataModel
import PocketCastsServer
import SafariServices
import UIKit

class ExpandedEpisodeListViewController: PCViewController, UITableViewDelegate, UITableViewDataSource, CollectionHeaderLinkDelegate {
    private let reuseIdentifier = String(describing: EpisodeListTableViewCell.self)

    private let tableView = ThemeableTable()
    private let podcastCollection: PodcastCollection
    private let episodes: [DiscoverEpisode]
    private let headerView: EpisodeListHeaderView
    private var cancellables = Set<AnyCancellable>()
    public var delegate: DiscoverDelegate? = nil

    init(podcastCollection: PodcastCollection) {
        self.podcastCollection = podcastCollection
        headerView = EpisodeListHeaderView(collection: podcastCollection)
        episodes = podcastCollection.episodes ?? []
        super.init(nibName: nil, bundle: nil)

        title = podcastCollection.subtitle
        headerView.linkDelegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func observeHeaderFrameChanges() {
        headerView.$contentViewSize
            .receive(on: ImmediateScheduler.shared)
            .sink { [unowned self] size in
                if size.height != self.headerView.frame.height {
                    self.headerView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                    self.headerView.layoutIfNeeded()
                    self.tableView.tableHeaderView = headerView
                }
            }
            .store(in: &cancellables)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)

        tableView.anchorToAllSidesOf(view: view)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(EpisodeListTableViewCell.nib, forCellReuseIdentifier: reuseIdentifier)

        observeHeaderFrameChanges()
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        tableView.tableHeaderView = headerView

        tableView.estimatedRowHeight = EpisodeListTableViewCell.estimatedCellHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: tableView)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! EpisodeListTableViewCell
        cell.viewModel.listId = podcastCollection.listId
        cell.viewModel.discoverEpisode = episodes[indexPath.row]
        cell.viewModel.delegate = delegate
        cell.colors = podcastCollection.colors
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        episodes.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = episodes[indexPath.row]

        guard let podcastUuid = episode.podcastUuid,
              let episodeUuid = episode.uuid else { return }

        if let listId = podcastCollection.listId {
            AnalyticsHelper.podcastEpisodeTapped(fromList: listId, podcastUuid: podcastUuid, episodeUuid: episodeUuid)
        }

        DiscoverEpisodeViewModel.loadPodcast(podcastUuid, episodeUuid: episodeUuid)
            .receive(on: RunLoop.main)
            .sink { [weak self] podcast in
                guard let podcast = podcast else {
                    self?.delegate?.failedToLoadEpisode()
                    return
                }
                self?.show(discoverEpisode: episode, podcast: podcast)
            }
            .store(in: &cancellables)
    }

    func show(discoverEpisode: DiscoverEpisode, podcast: Podcast) {
        guard let uuid = discoverEpisode.uuid else { return }
        let episodeController = EpisodeDetailViewController(episodeUuid: uuid, podcast: podcast, source: .discover)
        episodeController.modalPresentationStyle = .formSheet

        present(episodeController, animated: true)
    }

    func linkTapped() {
        guard let link = podcastCollection.webUrl, let url = URL(string: link) else { return }

        if Settings.openLinks {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            present(SFSafariViewController(with: url), animated: true, completion: nil)
        }
    }
}

extension ExpandedEpisodeListViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .discoverEpisodeList
    }
}
