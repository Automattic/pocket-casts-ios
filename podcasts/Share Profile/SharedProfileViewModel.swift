import Foundation
import PocketCastsDataModel
import PocketCastsServer
import SwiftUI

class SharedProfileViewModel: ObservableObject {
    struct ProfileData {
        let displayName: String
        let photoURL: URL?
        let podcasts: [PodcastInfo]
        let episodes: [EpisodeInfo]
    }

    struct PodcastInfo: Identifiable {
        let id: String
        let uuid: String
        let title: String
        let author: String?
        let artworkURL: URL?
    }

    struct EpisodeInfo: Identifiable {
        let id: String
        let uuid: String
        let podcastUuid: String
        let title: String
        let podcastTitle: String?
        let publishedDate: Date?
        let duration: TimeInterval
        let artworkURL: URL?
    }

    enum State {
        case loading
        case loaded(ProfileData)
        case error(String)
    }

    @Published var state: State = .loading
    @Published var subscribedUuids: Set<String> = []

    let profileSlug: String

    init(profileSlug: String) {
        self.profileSlug = profileSlug
        loadProfile()
    }

    var profileData: ProfileData? {
        if case .loaded(let data) = state { return data }
        return nil
    }

    func isSubscribed(podcastUuid: String) -> Bool {
        if subscribedUuids.contains(podcastUuid) { return true }
        return DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: false) != nil
    }

    func subscribeToPodcast(uuid: String) {
        subscribedUuids.insert(uuid)
        ServerPodcastManager.shared.subscribe(to: uuid, completion: nil)
    }

    func playEpisode(uuid: String, podcastUuid: String) {
        ServerPodcastManager.shared.addFromUuid(podcastUuid: podcastUuid, subscribe: false) { success in
            guard success, let episode = DataManager.sharedManager.findEpisode(uuid: uuid) else { return }
            DispatchQueue.main.async {
                PlaybackActionHelper.play(episode: episode, podcastUuid: podcastUuid)
            }
        }
    }

    private func loadProfile() {
        // TODO: Replace with real API call
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))

            let mockData = ProfileData(
                displayName: "Dom",
                photoURL: nil,
                podcasts: [
                    PodcastInfo(id: "1", uuid: "da3271a0-69e7-0132-d9fd-5f4c86fd3263", title: "Only a Game", author: "WBUR", artworkURL: ServerHelper.imageUrl(podcastUuid: "da3271a0-69e7-0132-d9fd-5f4c86fd3263", size: 200)),
                    PodcastInfo(id: "2", uuid: "3782b780-0bc5-012e-fb02-00163e46d440", title: "The Daily", author: "The New York Times", artworkURL: ServerHelper.imageUrl(podcastUuid: "3782b780-0bc5-012e-fb02-00163e46d440", size: 200)),
                    PodcastInfo(id: "3", uuid: "0d10b550-e227-0133-2e8b-6dc413d6d41d", title: "Radiolab", author: "WNYC Studios", artworkURL: ServerHelper.imageUrl(podcastUuid: "0d10b550-e227-0133-2e8b-6dc413d6d41d", size: 200)),
                ],
                episodes: [
                    EpisodeInfo(id: "1", uuid: "ep-1", podcastUuid: "da3271a0-69e7-0132-d9fd-5f4c86fd3263", title: "Episode 1: Origins", podcastTitle: "Only a Game", publishedDate: Date().addingTimeInterval(-86400 * 3), duration: 2400, artworkURL: ServerHelper.imageUrl(podcastUuid: "da3271a0-69e7-0132-d9fd-5f4c86fd3263", size: 200)),
                    EpisodeInfo(id: "2", uuid: "ep-2", podcastUuid: "3782b780-0bc5-012e-fb02-00163e46d440", title: "Switched at Birth", podcastTitle: "The Daily", publishedDate: Date().addingTimeInterval(-86400 * 5), duration: 1800, artworkURL: ServerHelper.imageUrl(podcastUuid: "3782b780-0bc5-012e-fb02-00163e46d440", size: 200)),
                    EpisodeInfo(id: "3", uuid: "ep-3", podcastUuid: "0d10b550-e227-0133-2e8b-6dc413d6d41d", title: "Comedy", podcastTitle: "Radiolab", publishedDate: Date().addingTimeInterval(-86400 * 7), duration: 3600, artworkURL: ServerHelper.imageUrl(podcastUuid: "0d10b550-e227-0133-2e8b-6dc413d6d41d", size: 200)),
                ]
            )

            self.state = .loaded(mockData)
        }
    }
}
