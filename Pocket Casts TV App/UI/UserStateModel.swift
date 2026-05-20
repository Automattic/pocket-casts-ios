import PocketCastsServer
import Combine

@Observable
class UserStateModel {

    private var cancellables: Set<AnyCancellable> = []

    var isPlusUser: Bool
    var isLoggedIn: Bool
    var usernameEmail: String?

    var usernameLabel: String {
        let usernameLabel = isLoggedIn ? (usernameEmail ?? "") : L10n.signedOut
        return usernameLabel
    }

    init() {
        isPlusUser = SubscriptionHelper.hasActiveSubscription()
        isLoggedIn = SyncManager.isUserLoggedIn()
        usernameEmail = ServerSettings.syncingEmail()
        setupObservers()
    }

    func refresh() {
        isPlusUser = SubscriptionHelper.hasActiveSubscription()
        isLoggedIn = SyncManager.isUserLoggedIn()
        usernameEmail = ServerSettings.syncingEmail()
    }

    private func setupObservers() {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: ServerNotifications.subscriptionStatusChanged),
            NotificationCenter.default.publisher(for: .userLoginDidChange)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            guard let self else {
                return
            }
            refresh()
        }
        .store(in: &cancellables)
    }

    func logout() {
        Task {
            SignOutHelper.signout()
            refresh()
        }
    }
}
