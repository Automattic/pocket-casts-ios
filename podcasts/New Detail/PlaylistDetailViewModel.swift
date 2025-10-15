import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import DifferenceKit

class PlaylistDetailViewModel: ObservableObject {
    typealias DataSourceValue = [ArraySection<Section, ListItem>]

    enum Section: String, ContentEquatable, ContentIdentifiable {
        case header
        case episodes

        func isContentEqual(to source: PlaylistDetailViewModel.Section) -> Bool {
            self == source
        }
    }
    enum ButtonTag {
        case smartRules
        case addEpisodes
        case playAll
    }

    let onButtonTapped: (ButtonTag) -> Void

    var episodes: [ListEpisode] {
        dataSource[safe: 1]?.elements as? [ListEpisode] ?? []
    }

    var isManualPlaylist: Bool {
        playlist.manual
    }

    var hasSubscribedPodcasts: Bool {
        dataManager.podcastCount() > 0
    }

    @Published private(set) var dataSource: DataSourceValue = []
    @Published var images: [PlaylistArtworkView.ImageItem] = []
    @Published var episodesCount: Int = 0
    @Published var playlistName: String = ""

    private(set) var playlist: EpisodeFilter!
    private(set) var isSearching = false
    private(set) var firstTimeLoading = true

    private var searchTerm: String = ""
    private var isLoadingData: Bool = false
    private let dataManager: DataManager
    private let imageManager: ImageManager
    private let episodesDataManager: EpisodesDataManager
    private let onChange: (StagedChangeset<DataSourceValue>, Bool, Bool) -> Void
    private var tempEpisodes: [ListEpisode] = []

    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    init(
        playlist: EpisodeFilter,
        dataManager: DataManager = .sharedManager,
        imageManager: ImageManager = .sharedManager,
        episodesDataManager: EpisodesDataManager = .init(),
        onChange: @escaping (StagedChangeset<DataSourceValue>, Bool, Bool) -> Void,
        onButtonTapped: @escaping (ButtonTag) -> Void
    ) {
        self.playlist = playlist
        self.dataManager = dataManager
        self.imageManager = imageManager
        self.episodesDataManager = episodesDataManager
        self.onChange = onChange
        self.onButtonTapped = onButtonTapped
    }

    func update(data: DataSourceValue) {
        self.dataSource = data

        if isLoadingData { return }
        isLoadingData = true

        Task { [weak self] in
            guard let self else { return }
            do {
                let count = await self.getEpisodesCount()
                if self.isSearching {
                    await MainActor.run {
                        self.episodesCount = count
                        self.isLoadingData = false
                    }
                } else {
                    let firstFourDistinct = self.firstDistinctPodcasts(from: self.episodes, limit: 4)
                    let images = try await self.loadImagesURLs(episodes: firstFourDistinct)
                    await MainActor.run {
                        self.images = images
                        self.episodesCount = count
                        self.isLoadingData = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingData = false
                }
            }
        }
    }

    func update(playlist: EpisodeFilter) {
        self.playlist = playlist
    }

    func reloadPlaylistAndEpisodes() {
        if isSearching {
            searchEpisodes(for: searchTerm)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            if let reloadedPlaylist = DataManager.sharedManager.findPlaylist(uuid: playlist.uuid) {
                playlist = reloadedPlaylist

                DispatchQueue.main.async { [weak self] in
                    self?.playlistName = reloadedPlaylist.playlistName
                }
            }
            reloadEpisodeList(animated: false)
        }
    }

    func reloadEpisodeList(animated: Bool = true) {
        if isSearching {
            searchEpisodes(for: searchTerm)
            return
        }
        operationQueue.cancelAllOperations()

        let refreshOperation = PlaylistRefreshOperation(playlist: playlist) { [weak self] newData in
            guard let self else { return }
            DispatchQueue.main.async {
                if self.firstTimeLoading {
                    self.firstTimeLoading.toggle()
                }
                let changeSetTuple = self.buildChangeSet(source: self.episodes, newData: newData)
                self.onChange(changeSetTuple.1, animated, changeSetTuple.0)
            }
        }
        operationQueue.addOperation(refreshOperation)
    }

    func totalDuration() -> String {
        let totalDuration = episodes.map { $0.episode.duration - $0.episode.playedUpTo }.reduce(0, +)
        return TimeFormatter.shared.multipleUnitFormattedShortTime(time: totalDuration)
    }

    func unarchivedEpisodesCount() -> Int {
        return 1 // TODO: query playlist unarchived episodes
    }

    func delete(episodes uuids: [String]) {
        dataManager.deleteEpisodes(uuids, from: playlist)
    }

    func move(episode: ListEpisode, toIndex index: Int) {
        dataManager.moveEpisode(episode.episode.uuid, in: playlist, to: index)
    }

    func updatePlaylist(sortType type: PlaylistSort) {
        if playlist.sortType == type.rawValue { return }
        playlist.syncStatus = SyncStatus.notSynced.rawValue
        playlist.sortType = type.rawValue
        dataManager.save(playlist: playlist)
    }

    private func buildChangeSet(
        source: [ListEpisode],
        newData: [ListEpisode]
    ) -> (Bool, StagedChangeset<DataSourceValue>) {
        let oldData = dataSource
        var finalData: [ArraySection<Section, ListItem>] = []
        let contentChanged = !source.isContentEqual(to: newData)
        let changedData = contentChanged ? newData : episodes
        finalData.append(ArraySection(
            model: .header,
            elements: [
                PlaylistHeaderViewCellPlaceholder()
            ])
        )
        if newData.isEmpty {
            finalData.append(ArraySection(
                model: .episodes,
                elements: [
                    NoSearchResultsPlaceholder()
                ])
            )
        } else {
            finalData.append(ArraySection(
                model: .episodes,
                elements: changedData)
            )
        }
        return (contentChanged, StagedChangeset(source: oldData, target: finalData))
    }

    private func loadImagesURLs(episodes: [ListEpisode], includingEpisodeArtwork: Bool = false) async throws -> [PlaylistArtworkView.ImageItem] {
        try await withThrowingTaskGroup(of: PlaylistArtworkView.ImageItem.self) { group in
            for episode in episodes {
                group.addTask {
                    if includingEpisodeArtwork,
                       let imageUrl = try await ShowInfoCoordinator.shared.loadEpisodeArtworkUrl(podcastUuid: episode.episode.podcastUuid, episodeUuid: episode.episode.uuid),
                       let url = URL(string: imageUrl) {
                        return PlaylistArtworkView.ImageItem(id: episode.episode.uuid, url: url)
                    }
                    let url = self.imageManager.podcastUrl(imageSize: .grid, uuid: episode.episode.podcastUuid)
                    return PlaylistArtworkView.ImageItem(id: episode.episode.podcastUuid, url: url)
                }
            }
            var results: [PlaylistArtworkView.ImageItem] = []
            for try await item in group {
                results.append(item)
            }

            let mapEpisodes = Dictionary(uniqueKeysWithValues: episodes.enumerated().map { ($1.episode.uuid, $0) })
            let mapPodcasts = Dictionary(uniqueKeysWithValues: episodes.enumerated().map { ($1.episode.podcastUuid, $0) })

            return results.sorted { lhs, rhs in
                let lhsIndex = (mapEpisodes[lhs.id] ?? mapPodcasts[lhs.id]) ?? Int.max
                let rhsIndex = (mapEpisodes[rhs.id] ?? mapPodcasts[rhs.id]) ?? Int.max
                return lhsIndex < rhsIndex
            }
        }
    }

    private func getEpisodesCount() async -> Int {
        let playlist = self.playlist!
        let dataManager = self.dataManager
        return await Task.detached(priority: .userInitiated) {
            dataManager.playlistEpisodeCount(
                for: playlist,
                episodeUuidToAdd: playlist.episodeUuidToAddToQueries()
            )
        }.value
    }

    private func firstDistinctPodcasts(from episodes: [ListEpisode], limit: Int) -> [ListEpisode] {
        var seen = Set<String>()
        var list: [ListEpisode] = []

        for episode in episodes {
            if seen.insert(episode.episode.podcastUuid).inserted {
                list.append(episode)
                if list.count == limit {
                    break
                }
            }
        }
        return list
    }
}

extension PlaylistDetailViewModel {
    func clearSearch() {
        searchTerm = ""
        dataSource[1] = ArraySection(
            model: .episodes,
            elements: tempEpisodes)
    }

    func endSearch() {
        isSearching = false
        searchTerm = ""
        dataSource[1] = ArraySection(
            model: .episodes,
            elements: tempEpisodes)
        tempEpisodes.removeAll()

        reloadPlaylistAndEpisodes()
    }

    func startSearch() {
        if isSearching {
            return
        }
        isSearching = true
        tempEpisodes = episodes
    }

    func searchEpisodes(for searchTerm: String) {
        if searchTerm.isEmpty {
            return
        }
        self.searchTerm = searchTerm
        let escapedSearch = searchTerm.escapeLike(escapeChar: "\\")
        let newData = episodesDataManager.playlistEpisodes(for: playlist, limit: 0, search: escapedSearch)
        let changeSetTuple = buildChangeSet(source: episodes, newData: newData)
        DispatchQueue.main.async { [weak self] in
            self?.onChange(changeSetTuple.1, true, changeSetTuple.0)
        }
    }
}
