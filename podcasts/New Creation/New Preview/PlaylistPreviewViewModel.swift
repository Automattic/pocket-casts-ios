import Foundation
import PocketCastsDataModel
import PocketCastsUtils

class PlaylistPreviewViewModel: ObservableObject {
    enum PlaylistMode {
        case creation
        case edit
    }

    @Published var newPlaylistHasChanged: Bool = false

    private(set) var isInPreview: Bool = false
    private(set) var newPlaylist: EpisodeFilter
    private(set) var enabledRules: [SmartPlaylistRuleInfo] = []
    private(set) var availableRules: [SmartPlaylistRuleInfo] = []
    private(set) var episodes = [ListEpisode]()

    let playlistMode: PlaylistMode
    let action: (SmartPlaylistRule) -> Void

    deinit {
        removeObserver()
    }

    init(newPlaylist: EpisodeFilter, playlistMode: PlaylistMode, action: @escaping (SmartPlaylistRule) -> Void) {
        self.newPlaylist = newPlaylist
        self.action = action
        self.playlistMode = playlistMode
        self.availableRules = SmartPlaylistRule.allCases.map { SmartPlaylistRuleInfo(type: $0) }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFilterChanged(_:)),
            name: Constants.Notifications.filterChanged,
            object: nil
        )
    }

    func smartRuleIsApplied(for rule: SmartPlaylistRule) -> Bool {
        switch rule {
        case .podcast:
            return newPlaylist.podcastSmartRuleApplied
        case .episode:
            return newPlaylist.episodesSmartRuleApplied
        case .downloadStatus:
            return newPlaylist.downloadStatusSmartRuleApplied
        case .mediaType:
            return newPlaylist.mediaTypeSmartRuleApplied
        case .releaseDate:
            return newPlaylist.releaseDateSmartRuleApplied
        case .starred:
            return newPlaylist.filterStarred
        case .duration:
            return newPlaylist.filterDuration
        }
    }

    func ruleText(for rule: SmartPlaylistRule) -> String? {
        switch rule {
        case .podcast:
            return newPlaylist.filterAllPodcasts ? L10n.filterValueAll : "\(newPlaylist.podcastUuids.components(separatedBy: ",").count)"
        case .episode:
            var episodeTypes: [String] = []
            if newPlaylist.filterUnplayed {
                episodeTypes.append(L10n.statusUnplayed)
            }
            if newPlaylist.filterPartiallyPlayed {
                episodeTypes.append(L10n.inProgress)
            }
            if newPlaylist.filterFinished {
                episodeTypes.append(L10n.statusPlayed)
            }
            if !episodeTypes.isEmpty {
                let returnedString = episodeTypes.first!
                let newEpisodeTypes = episodeTypes.dropFirst()
                if newEpisodeTypes.isEmpty {
                    return returnedString
                }
                return "\(returnedString) + \(newEpisodeTypes.count)"
            }
            return nil
        case .downloadStatus:
            if newPlaylist.filterDownloaded, !newPlaylist.filterNotDownloaded {
                return L10n.statusDownloaded
            } else if !newPlaylist.filterDownloaded, newPlaylist.filterNotDownloaded {
                return L10n.statusNotDownloaded
            } else {
                return L10n.filterValueAll
            }
        case .mediaType:
            if newPlaylist.filterAudioVideoType == AudioVideoFilter.audioOnly.rawValue {
                return AudioVideoFilter.audioOnly.description
            } else if newPlaylist.filterAudioVideoType == AudioVideoFilter.videoOnly.rawValue {
                return AudioVideoFilter.videoOnly.description
            } else {
                return L10n.filterValueAll
            }
        case .releaseDate:
            return ReleaseDateFilterOption(rawValue: newPlaylist.filterHours)?.description
        case .starred:
            return newPlaylist.filterStarred ? "\(episodes.count)" : nil
        case .duration:
            if newPlaylist.filterDuration {
                let shortTime = TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(newPlaylist.shorterThan * 60))
                let longTime = TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(newPlaylist.longerThan * 60))
                return "\(longTime) - \(shortTime)"
            }
            return nil
        }
    }

    @objc private func handleFilterChanged(_ notification: Notification) {
        guard let playlist = notification.object as? EpisodeFilter,
              playlist.uuid == newPlaylist.uuid
        else {
            return
        }
        newPlaylist = playlist

        if playlistMode == .edit {
            enabledRules = SmartPlaylistRule.allCases.map {
                let ruleText = ruleText(for: $0)
                return SmartPlaylistRuleInfo(type: $0, description: ruleText)
            }
            newPlaylistHasChanged = true
            return
        }

        newPlaylist.isNew = true
        isInPreview = true

        enabledRules.removeAll()
        availableRules.removeAll()

        for rule in SmartPlaylistRule.allCases {
            if smartRuleIsApplied(for: rule) {
                let ruleText = ruleText(for: rule)
                enabledRules.append(SmartPlaylistRuleInfo(type: rule, description: ruleText))
            } else {
                availableRules.append(SmartPlaylistRuleInfo(type: rule))
            }
        }

        newPlaylistHasChanged = true
    }

    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
}
