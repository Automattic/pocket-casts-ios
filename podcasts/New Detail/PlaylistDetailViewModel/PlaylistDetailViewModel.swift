import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import DifferenceKit
import PocketCastsDependencyInjection

class PlaylistDetailViewModel: ObservableObject {
    @Dependency(\.playlistMetadataLoader) var playlistMetadataLoader: PlaylistMetadataLoader

    typealias DataSourceValue = [ArraySection<Section, ListItem>]

    enum Section: String, ContentEquatable, ContentIdentifiable {
        case header
        case archive
        case episodes

        func isContentEqual(to source: Section) -> Bool {
            self == source
        }
    }

    enum ButtonTag {
        case smartRules
        case addEpisodes
        case playAll
    }

    let onButtonTapped: (ButtonTag) -> Void
    let dataManager: DataManager
    let episodesDataManager: EpisodesDataManager

    var episodes: [ListEpisode] {
        dataSource.first(where: { $0.model == .episodes })?.elements as? [ListEpisode] ?? []
    }

    var isManualPlaylist: Bool {
        playlist.manual
    }

    var hasSubscribedPodcasts: Bool {
        dataManager.podcastCount() > 0
    }

    var isPlaylistFull: Bool {
#if DEBUG
        playlistEpisodesCount >= Settings.debugPlaylistsLimit
#else
        playlistEpisodesCount >= Constants.Limits.maxFilterItems
#endif
    }

    @Published private(set) var dataSource: DataSourceValue = []
    @Published var images: [PlaylistArtworkView.ImageItem] = []
    @Published var playlistEpisodesCount: Int = 0
    @Published var playlistName: String = ""

    private(set) var playlist: EpisodeFilter!
    private(set) var isSearching = false
    private(set) var firstTimeLoading = true
    private(set) var archivedEpisodesCount: Int = 0

    private var searchTerm: String = ""
    private var artworkLoadingTask: Task<Void, Never>?
    private let imageManager: ImageManager
    private let onChange: (StagedChangeset<DataSourceValue>, Bool, Bool) -> Void
    private var tempEpisodes: [ListEpisode] = []
    private let artworkImagesLimit = 4

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
        self.dataSource = makeSections(episodes: [])
    }

    func update(data: DataSourceValue, then block: (() -> Void)? = nil) {
        self.dataSource = data

        artworkLoadingTask?.cancel()

        // Capture the newly updated episodes on the main thread before entering the async task
        let currentEpisodes = self.episodes

        artworkLoadingTask = Task { [weak self] in
            guard let self else { return }
            do {
                let count = await self.playlistMetadataLoader.loadCount(for: self.playlist)
                if self.isSearching {
                    await MainActor.run {
                        self.playlistEpisodesCount = count
                    }
                } else {
                    let firstFourDistinct = self.firstDistinctPodcasts(from: currentEpisodes, limit: self.artworkImagesLimit)
                    let images = try await self.loadImagesURLs(episodes: firstFourDistinct)

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.images = images
                        self.playlistEpisodesCount = count
                        block?()
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    block?()
                }
            }
        }
    }

    func update(playlist: EpisodeFilter) {
        self.playlist = playlist
    }

    func reloadPlaylistAndEpisodes() {
        if isSearching, !searchTerm.isEmpty {
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
            reloadEpisodeList(animated: true)
        }
    }

    func reloadEpisodeList(animated: Bool = true) {
        if isSearching, !searchTerm.isEmpty {
            searchEpisodes(for: searchTerm)
            return
        }
        operationQueue.cancelAllOperations()

        let refreshOperation = PlaylistDetailFetchOperation(
            dataManager: dataManager,
            episodesDataManager: episodesDataManager,
            playlist: playlist,
            shouldShowArchived: playlist.showArchivedEpisodes
        ) { [weak self] newData, archivedEpisodeCount in
            guard let self else { return }
            DispatchQueue.main.async {
                self.archivedEpisodesCount = archivedEpisodeCount
                let isFirstReload = self.firstTimeLoading
                self.firstTimeLoading = false
                let changeSetTuple = self.buildChangeSet(source: self.episodes, newData: newData)
                let contentHasChanged = changeSetTuple.0
                if contentHasChanged {
                    self.dataManager.updatePlaylistUpdateDate(for: self.playlist)
                }
                self.onChange(changeSetTuple.1, animated && !isFirstReload, contentHasChanged)
            }
        }
        operationQueue.addOperation(refreshOperation)
    }

    func totalDuration() -> String? {
        let totalDuration = episodes.map { $0.episode.duration - $0.episode.playedUpTo }.reduce(0, +)
        if totalDuration <= 0 {
            return nil
        }
        let formattedDuration = TimeFormatter.shared.multipleUnitFormattedShortTime(time: totalDuration)
        return formattedDuration.isEmpty ? nil : formattedDuration
    }

    func delete(episodes uuids: [String]) {
        dataManager.deleteEpisodes(uuids, from: playlist)
    }

    func remove(episode uuid: String, at index: Int) {
        var newData = episodes
        newData.remove(at: index)
        let changeSetTuple = buildChangeSet(source: episodes, newData: newData)
        onChange(changeSetTuple.1, true, changeSetTuple.0)

        delete(episodes: [uuid])
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
        let oldSections = dataSource
        let contentChanged = !source.isContentEqual(to: newData)
        let effectiveEpisodes = contentChanged ? newData : episodes
        let newSections = makeSections(episodes: effectiveEpisodes)

        let changeset = StagedChangeset(
            source: oldSections,
            target: newSections
        )

        let contentHasChanged = !newSections.isContentEqual(to: oldSections) || contentChanged
        return (contentHasChanged, changeset)
    }

    private func makeSections(episodes: [ListEpisode]) -> DataSourceValue {
        var sections: DataSourceValue = [
            ArraySection(model: .header, elements: [PlaylistHeaderViewCellPlaceholder()])
        ]

        if isManualPlaylist {
            sections.append(
                ArraySection(
                    model: .archive,
                    elements: [
                        PlaylistArchiveViewCellPlaceholder(
                            archived: archivedEpisodesCount,
                            showArchived: shouldShowArchived
                        )
                    ]
                )
            )
        }

        let episodeElements: [ListItem]
        if episodes.isEmpty {
            if isSearching {
                episodeElements = [NoSearchResultsPlaceholder()]
            } else if isManualPlaylist, !shouldShowArchived {
                episodeElements = [
                    AllArchivedPlaceholder(
                        archived: archivedEpisodesCount,
                        message: archivedEpisodesCount == 1
                            ? L10n.playlistManualArchivedEpisodePlaceholder
                            : L10n.playlistManualArchivedEpisodesPlaceholder(archivedEpisodesCount)
                    )
                ]
            } else {
                episodeElements = []
            }
        } else {
            episodeElements = episodes
        }

        sections.append(ArraySection(model: .episodes, elements: episodeElements))
        return sections
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
                    let url = self.imageManager.podcastUrl(imageSize: .detail, uuid: episode.episode.podcastUuid)
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

    private func getPlaylistEpisodesCount() async -> Int {
        let playlist = self.playlist!
        let dataManager = self.dataManager
        return await Task.detached(priority: .userInitiated) {
            dataManager.allPlaylistEpisodeCount(
                for: playlist,
                episodeUuidToAdd: playlist.episodeUuidToAddToQueries(),
                includingArchivedEpisodes: playlist.manual
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

        if !list.isEmpty, list.count < limit {
            return Array(list.prefix(1))
        }
        return list
    }
}

extension PlaylistDetailViewModel {
    func clearSearch() {
        searchTerm = ""
        replaceEpisodesSection(with: tempEpisodes)
        reloadEpisodeList()
    }

    func endSearch() {
        isSearching = false
        searchTerm = ""
        replaceEpisodesSection(with: tempEpisodes)
        tempEpisodes.removeAll()

        reloadPlaylistAndEpisodes()
    }

    private func replaceEpisodesSection(with episodes: [ListEpisode]) {
        guard let index = dataSource.firstIndex(where: { $0.model == .episodes }) else { return }
        dataSource[index] = ArraySection(model: .episodes, elements: episodes)
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
        let newData = episodesDataManager.playlistEpisodes(for: playlist, limit: 0, shouldShowArchived: true, search: escapedSearch)
        let changeSetTuple = buildChangeSet(source: episodes, newData: newData)
        DispatchQueue.main.async { [weak self] in
            // Avoid animation as long we use the current diffable framework
            self?.onChange(changeSetTuple.1, false, changeSetTuple.0)
        }
    }
}
