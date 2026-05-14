import Foundation
import PocketCastsDataModel
import PocketCastsServer
import SwiftUI
import PhotosUI

class ShareProfileViewModel: ObservableObject {
    @Published var displayName: String = "" {
        didSet { Self.saveDisplayName(displayName) }
    }
    @Published var profilePhoto: UIImage? {
        didSet { Self.saveProfilePhoto(profilePhoto) }
    }
    @Published var shareFollowedPodcasts: Bool = true {
        didSet { UserDefaults.standard.set(shareFollowedPodcasts, forKey: Self.followedPodcastsKey) }
    }
    @Published var shareRecentEpisodes: Bool = true {
        didSet { UserDefaults.standard.set(shareRecentEpisodes, forKey: Self.recentEpisodesKey) }
    }
    @Published var sharePlaylists: Bool = true {
        didSet { UserDefaults.standard.set(sharePlaylists, forKey: Self.playlistsKey) }
    }

    static let followedPodcastsKey = "ShareProfileFollowedPodcasts"
    static let recentEpisodesKey = "ShareProfileRecentEpisodes"
    static let playlistsKey = "ShareProfilePlaylists"
    @Published var selectedPhotoItem: PhotosPickerItem? {
        didSet {
            loadPhoto()
        }
    }
    @Published var showingPhotoPicker = false
    @Published var showingCamera = false

    let email: String?

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
        displayName = Self.loadDisplayName() ?? ""
        profilePhoto = Self.loadProfilePhoto()
        shareFollowedPodcasts = UserDefaults.standard.object(forKey: Self.followedPodcastsKey) as? Bool ?? true
        shareRecentEpisodes = UserDefaults.standard.object(forKey: Self.recentEpisodesKey) as? Bool ?? true
        sharePlaylists = UserDefaults.standard.object(forKey: Self.playlistsKey) as? Bool ?? true
    }

    func removePhoto() {
        profilePhoto = nil
        selectedPhotoItem = nil
    }

    func podcastName(for episode: Episode) -> String? {
        DataManager.sharedManager.findPodcast(uuid: episode.podcastUuid, includeUnsubscribed: true)?.title
    }

    @MainActor
    func shareProfile(from viewController: UIViewController) {
        let cardView = ShareProfileCardView(viewModel: self)
            .environmentObject(Theme.sharedTheme)
            .frame(width: 340, height: 400)

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

    // MARK: - Persistence

    private static let displayNameKey = "ShareProfileDisplayName"

    private static func saveDisplayName(_ name: String) {
        UserDefaults.standard.set(name, forKey: displayNameKey)
    }

    private static func loadDisplayName() -> String? {
        UserDefaults.standard.string(forKey: displayNameKey)
    }

    private static var photoURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("share_profile_photo.jpg")
    }

    static let photoDidChangeNotification = Notification.Name("ShareProfilePhotoDidChange")

    private static func saveProfilePhoto(_ image: UIImage?) {
        guard let image, let data = image.jpegData(compressionQuality: 0.85) else {
            try? FileManager.default.removeItem(at: photoURL)
            NotificationCenter.default.post(name: photoDidChangeNotification, object: nil)
            return
        }
        try? data.write(to: photoURL)
        NotificationCenter.default.post(name: photoDidChangeNotification, object: nil)
    }

    private static func loadProfilePhoto() -> UIImage? {
        loadSavedProfilePhoto()
    }

    static func loadSavedProfilePhoto() -> UIImage? {
        guard FileManager.default.fileExists(atPath: photoURL.path) else { return nil }
        guard let data = try? Data(contentsOf: photoURL) else { return nil }
        return UIImage(data: data)
    }
}
