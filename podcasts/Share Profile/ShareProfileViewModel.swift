import Foundation
import PocketCastsDataModel
import PocketCastsServer
import SwiftUI
import PhotosUI

class ShareProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var profilePhoto: UIImage?
    @Published var shareFollowedPodcasts: Bool = true
    @Published var shareRecentEpisodes: Bool = true
    @Published var sharePlaylists: Bool = true
    @Published var selectedPhotoItem: PhotosPickerItem? {
        didSet {
            loadPhoto()
        }
    }

    let email: String?

    var onDismiss: (() -> Void)?

    var followedPodcasts: [Podcast] {
        DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
    }

    var recentEpisodes: [Episode] {
        DataManager.sharedManager.episodesWithListenHistory(limit: 10)
    }

    var playlists: [EpisodeFilter] {
        DataManager.sharedManager.allPlaylists(includeDeleted: false)
    }

    init() {
        email = SyncManager.isUserLoggedIn() ? ServerSettings.syncingEmail() : nil
    }

    func podcastName(for episode: Episode) -> String? {
        DataManager.sharedManager.findPodcast(uuid: episode.podcastUuid, includeUnsubscribed: true)?.title
    }

    @MainActor
    func shareProfile(from viewController: UIViewController) {
        let cardView = ShareProfileCardView(viewModel: self)
            .environmentObject(Theme.sharedTheme)
            .frame(width: 390, height: 520)

        let image = cardView.snapshot()

        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = viewController.view
        viewController.present(activityVC, animated: true)
    }

    private func loadPhoto() {
        guard let item = selectedPhotoItem else { return }
        item.loadTransferable(type: Data.self) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let data) = result, let data, let image = UIImage(data: data) {
                    self?.profilePhoto = image
                }
            }
        }
    }
}
