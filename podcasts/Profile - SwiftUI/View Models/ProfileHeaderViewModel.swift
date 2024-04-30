import Foundation

/// View model for the header view that appears on the Profile tab view
class ProfileHeaderViewModel: ProfileDataViewModel {
    weak var navigationController: UINavigationController? = nil
    let shouldShowProfileInfo: Bool
    init(navigationController: UINavigationController? = nil, shouldShowProfileInfo: Bool = true) {
        self.shouldShowProfileInfo = shouldShowProfileInfo
        super.init()

        self.navigationController = navigationController
    }

    /// Opens the login or account details depending on the users logged in state
    func accountTapped() {
        Analytics.track(.profileAccountButtonTapped)

        guard profile.isLoggedIn else {
            // Show the login flow
            NavigationManager.sharedManager.navigateTo(NavigationManager.onboardingFlow,
                                                       data: ["flow": OnboardingFlow.Flow.loggedOut])
            return
        }

        navigationController?.pushViewController(AccountViewController(), animated: true)
    }
}
