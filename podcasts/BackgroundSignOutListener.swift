import Foundation
import PocketCastsServer

/// Listens for the user sign out notification and if it was not user initiated then we'll show
/// and alert to the user asking them to sign in again
class BackgroundSignOutListener {
    private let notificationCenter: NotificationCenter
    private let navigationManager: NavigationManager

    private var presentingViewController: () -> UIViewController?

    private var canShowSignOut = true

    init(notificationCenter: NotificationCenter = NotificationCenter.default,
         navigationManager: NavigationManager = NavigationManager.sharedManager,
         presentingViewController: @autoclosure @escaping () -> UIViewController?) {
        self.notificationCenter = notificationCenter
        self.navigationManager = navigationManager
        self.presentingViewController = presentingViewController

        addNotificationObservers()
    }

    deinit {
        removeNotificationObservers()
    }

    func showSignIn() {
        canShowSignOut = true
        navigationManager.navigateTo(NavigationManager.onboardingFlow, data: ["flow": OnboardingFlow.Flow.forcedLoggedOut])
    }
}

// MARK: - Private: Notifications

private extension BackgroundSignOutListener {
    func removeNotificationObservers() {
        notificationCenter.removeObserver(self, name: .serverUserWillBeSignedOut, object: nil)
    }

    func addNotificationObservers() {
        notificationCenter.addObserver(forName: .serverUserWillBeSignedOut, object: nil, queue: .main) { [weak self] notification in
            self?.handleSignOutNotification(notification)
        }
    }

    func handleSignOutNotification(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let userInitiated = userInfo["user_initiated"] as? Bool,
            userInitiated == false
        else {
            return
        }

        showAlertIfPossible()
    }
}

// MARK: - Alert Showing

private extension BackgroundSignOutListener {
    func showAlertIfPossible() {
        // If we're already showing the sign out then don't try to show it again
        guard canShowSignOut else {
            return
        }

        canShowSignOut = false

        Analytics.track(.signedOutAlertShown)

        let alert = UIAlertController(title: L10n.accountSignedOutAlertTitle, message: L10n.accountSignedOutAlertMessage, preferredStyle: .alert)

        let okAction = UIAlertAction(title: L10n.signIn, style: .default, handler: { [weak self] _ in
            self?.showSignIn()
        })

        alert.addAction(okAction)

        presentingViewController()?.present(alert, animated: true, completion: nil)
    }
}
