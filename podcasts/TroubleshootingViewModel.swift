import Foundation
import PocketCastsDataModel

@MainActor
class TroubleshootingViewModel: ObservableObject {
    enum OrphanedEpisodesState {
        case checking
        case found(episodes: [Episode])
        case removing
    }

    @Published private(set) var orphanedEpisodesState: OrphanedEpisodesState = .checking
    @Published private(set) var lastRemovedCount: Int?

    private let source: OnlineSupportController.Source

    init(source: OnlineSupportController.Source) {
        self.source = source
    }

    func checkOrphanedEpisodes() {
        orphanedEpisodesState = .checking

        Task.detached(priority: .userInitiated) { [weak self] in
            let episodes = DataManager.sharedManager.findOrphanedEpisodes()
            await self?.setFound(episodes: episodes)
        }
    }

    func removeOrphanedEpisodes() {
        let countBefore = episodeCount
        orphanedEpisodesState = .removing
        lastRemovedCount = nil

        Analytics.track(.troubleshootingOrphanedEpisodesRemoveConfirmed, properties: ["source": source.rawValue])

        Task.detached(priority: .userInitiated) { [weak self] in
            PodcastManager.shared.deleteOrphanedEpisodesIfNeeded()
            let remaining = DataManager.sharedManager.findOrphanedEpisodes()
            await self?.finishRemoving(countBefore: countBefore, remaining: remaining)
        }
    }

    private var episodeCount: Int {
        if case .found(let episodes) = orphanedEpisodesState {
            return episodes.count
        }
        return 0
    }

    private func setFound(episodes: [Episode]) {
        orphanedEpisodesState = .found(episodes: episodes)
    }

    private func finishRemoving(countBefore: Int, remaining: [Episode]) {
        let removedCount = max(0, countBefore - remaining.count)
        lastRemovedCount = removedCount
        orphanedEpisodesState = .found(episodes: remaining)

        Analytics.track(.troubleshootingOrphanedEpisodesRemoved, properties: ["source": source.rawValue, "removed": removedCount, "remaining": remaining.count])
    }
}
