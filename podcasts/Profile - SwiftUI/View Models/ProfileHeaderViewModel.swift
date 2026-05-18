import Foundation
import SwiftUI

/// View model for the header view that appears on the Profile tab view
class ProfileHeaderViewModel: ProfileDataViewModel {
    weak var navigationController: UINavigationController? = nil

    init(navigationController: UINavigationController? = nil) {
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

    func editPhotoAndNameTapped() {
        guard let presenter = navigationController?.topViewController else { return }

        let viewModel = ShareProfileViewModel()
        let editView = EditPhotoAndNameView(viewModel: viewModel, dismissAction: {
            presenter.dismiss(animated: true)
        })

        let hostingController = PCHostingController(rootView: editView)
        presenter.present(hostingController, animated: true)
    }

    func shareTapped() {
        guard let presenter = navigationController?.topViewController else { return }

        let shareView = ShareProfileView {
            presenter.dismiss(animated: true)
        } onOpenPrivacySettings: { [weak self] in
            presenter.dismiss(animated: true) {
                self?.navigationController?.pushViewController(PrivacySettingsViewController(), animated: true)
            }
        }

        let hostingController = PCHostingController(rootView: shareView)
        presenter.present(hostingController, animated: true)
    }
}
