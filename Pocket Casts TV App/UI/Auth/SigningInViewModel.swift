import SwiftUI
import Combine
import PocketCastsServer
import PocketCastsUtils

@Observable
class SigningInViewModel {
    private var cancellables: Set<AnyCancellable> = []

    enum State: Equatable, Hashable {
        case waiting
        case finished
    }
    var state: State = .waiting

    var podcasts: [MockPodcast] = MockData.makePodcasts()

    var totalPodcastsToImport: Int = -1
    var totalPodcastsImported: Int = 0
    var title: String?
    var progress: CGFloat = 0

    func sync() {
        NotificationCenter.default.publisher(for: ServerNotifications.syncProgressPodcastCount)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self else {
                    return
                }
                if let number = notification.object as? NSNumber {
                    totalPodcastsToImport = number.intValue
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: ServerNotifications.syncProgressPodcastUpto)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self,
                      let number = notification.object as? NSNumber
                else {
                    return
                }

                totalPodcastsImported = number.intValue
                if totalPodcastsToImport > 0 {
                    title = L10n.syncProgress(totalPodcastsImported.localized(), totalPodcastsToImport.localized())
                    progress = CGFloat(totalPodcastsImported / totalPodcastsToImport)
                } else {
                    // Used when the total number of podcasts to sync isn't known.
                    title = totalPodcastsImported == 1 ? L10n.syncProgressUnknownCountSingular : L10n.syncProgressUnknownCountPluralFormat(totalPodcastsImported.localized())
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: ServerNotifications.syncProgressImportedPodcasts)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }

                title = L10n.syncInProgress
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .userLoginDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }

                title = L10n.syncAccountLogin
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: ServerNotifications.syncCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                state = .finished
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: ServerNotifications.syncFailed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                state = .finished
            }
            .store(in: &cancellables)
    }
}
