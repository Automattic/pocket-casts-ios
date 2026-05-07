import SwiftUI
import Combine
import PocketCastsServer
import PocketCastsUtils
import PocketCastsDataModel

protocol SigningInViewModelInterface: AnyObject, Observation.Observable {
    var totalPodcastsToImport: Int { get }
    var totalPodcastsImported: Int { get }
    var title: String? { get }
    var progress: CGFloat { get }
}

enum SigningInState: Equatable, Hashable {
    case waiting
    case finished
}

@Observable
class SigningInViewModel: SigningInViewModelInterface {
    private var cancellables: Set<AnyCancellable> = []

    private(set) var state: SigningInState = .waiting

    var podcasts: [Podcast] = []

    var totalPodcastsToImport: Int = -1
    var totalPodcastsImported: Int = 0
    var title: String?
    var progress: CGFloat = 0

    private let dataManager: DataManager

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
    }

    func sync() {
        guard cancellables.isEmpty else {
            return
        }
        observeSyncProgressPodcastsCount()
        observeSyncProgressProgressPodcasts()
        observeSyncProgressImported()
        observeSyncCompleted()
        observeSyncFailed()
        observeUserLoginDidChange()
    }

    private func fetchPodcasts() {
        Task {
            let podcasts = dataManager.allPodcasts(includeUnsubscribed: false, reloadFromDatabase: true)
            await MainActor.run {
                self.podcasts = podcasts
            }
        }
    }

    private func observeSyncProgressPodcastsCount() {
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
    }

    private func observeSyncProgressProgressPodcasts() {
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
                    progress = CGFloat(totalPodcastsImported) / CGFloat(totalPodcastsToImport)
                } else {
                    // Used when the total number of podcasts to sync isn't known.
                    title = totalPodcastsImported == 1 ? L10n.syncProgressUnknownCountSingular : L10n.syncProgressUnknownCountPluralFormat(totalPodcastsImported.localized())
                }
                fetchPodcasts()
            }
            .store(in: &cancellables)
    }

    fileprivate func observeSyncProgressImported() {
        NotificationCenter.default.publisher(for: ServerNotifications.syncProgressImportedPodcasts)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }

                title = L10n.syncInProgress
            }
            .store(in: &cancellables)
    }

    fileprivate func observeUserLoginDidChange() {
        NotificationCenter.default.publisher(for: .userLoginDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }

                title = L10n.syncAccountLogin
            }
            .store(in: &cancellables)
    }

    fileprivate func observeSyncCompleted() {
        NotificationCenter.default.publisher(for: ServerNotifications.syncCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                state = .finished
            }
            .store(in: &cancellables)
    }

    fileprivate func observeSyncFailed() {
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

@Observable
class SigningInViewModelMock: SigningInViewModelInterface {

    private var cancellable: AnyCancellable?

    var state: SigningInState = .waiting

    var totalPodcastsToImport: Int = MockData.makePodcasts().count

    var totalPodcastsImported: Int = 0

    var title: String?

    var progress: CGFloat = 0

    var podcasts: [MockPodcast] = MockData.makePodcasts()

    func sync() {
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in
                        guard let self else { return }

                        if totalPodcastsImported < totalPodcastsToImport {
                            totalPodcastsImported += 1
                        } else {
                            state = .finished
                        }

                        progress = CGFloat(totalPodcastsImported) / CGFloat(totalPodcastsToImport)
                    }
    }
}

