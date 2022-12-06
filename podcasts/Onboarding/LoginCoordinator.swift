import Foundation
import PocketCastsServer
import SwiftUI
import PocketCastsDataModel

class LoginCoordinator: OnboardingModel {
    var navigationController: UINavigationController? = nil
    let headerImages: [LoginHeaderImage]
    var presentedFromUpgrade: Bool = false

    init() {
        let maxCount = bundledImages.count
        let bundledImages = bundledImages

        var randomPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: true)
            // Only return items we have a cached image for
            .filter {
                ImageManager.sharedManager.hasCachedImage(for: $0.uuid, size: .grid)
            }
            // Return a random-ish order
            .shuffled()
            // Limit to the number of bundled images we have
            .prefix(maxCount)
            // Convert the podcasts into the model, we use enumerated because we need the index to map to the placeholder
            .enumerated().map { (index, item) in
                LoginHeaderImage(podcast: item, imageName: nil, placeholderImageName: bundledImages[index].imageName ?? "")
            }

        // If there aren't enough podcasts in the database, then fill in the missing ones with bundled images
        if randomPodcasts.count < maxCount {
            randomPodcasts.append(contentsOf: bundledImages[randomPodcasts.count..<maxCount])
        }

        self.headerImages = randomPodcasts
    }

    func didAppear() {
        OnboardingFlow.shared.track(.setupAccountShown)
    }

    func didDismiss(type: OnboardingDismissType) {
        guard type == .swipe else { return }
        OnboardingFlow.shared.track(.setupAccountDismissed)
    }

    func loginTapped() {
        OnboardingFlow.shared.track(.setupAccountButtonTapped, properties: ["button": "sign_in"])
        let controller = SyncSigninViewController()
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }

    func signUpTapped() {
        OnboardingFlow.shared.track(.setupAccountButtonTapped, properties: ["button": "create_account"])
        let controller = NewEmailViewController(newSubscription: NewSubscription(isNewAccount: true, iap_identifier: ""))
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc func dismissTapped() {
        OnboardingFlow.shared.track(.setupAccountDismissed)
        navigationController?.dismiss(animated: true)
    }

    private let bundledImages: [LoginHeaderImage] = [
        .init(podcast: nil, imageName: "login-cover-1"),
        .init(podcast: nil, imageName: "login-cover-2"),
        .init(podcast: nil, imageName: "login-cover-3"),
        .init(podcast: nil, imageName: "login-cover-4"),
        .init(podcast: nil, imageName: "login-cover-5"),
        .init(podcast: nil, imageName: "login-cover-6"),
        .init(podcast: nil, imageName: "login-cover-7")
    ]

    struct LoginHeaderImage {
        let podcast: Podcast?
        let imageName: String?
        var placeholderImageName: String = ""
    }
}

// MARK: - Social Buttons
extension LoginCoordinator {
    func signInWithAppleTapped() { }
    func signInWithGoogleTapped() { }
}

extension LoginCoordinator: SyncSigninDelegate, CreateAccountDelegate {
    func signingProcessCompleted() {
        let shouldDismiss = SubscriptionHelper.hasActiveSubscription() && !presentedFromUpgrade

        if shouldDismiss {
            navigationController?.dismiss(animated: true) {
                DispatchQueue.main.async {
                    OnboardingFlow.shared.reset()
                }
            }
            return
        }

        goToPlus(from: .login)
    }

    func handleAccountCreated() {
        goToPlus(from: .accountCreated)
    }

    private func goToPlus(from source: PlusLandingViewModel.Source) {
        // Update the flow to make sure the correct analytics source is passed on
        OnboardingFlow.shared.updateAnalyticsSource(source == .login ? "login" : "account_created")

        let controller = PlusLandingViewModel.make(in: navigationController, from: source, continueUpgrade: presentedFromUpgrade)
        navigationController?.setViewControllers([controller], animated: true)
    }
}

// MARK: - Helpers

extension LoginCoordinator {
    static func make(in navigationController: UINavigationController? = nil, fromUpgrade: Bool = false) -> UIViewController {
        let coordinator = LoginCoordinator()
        coordinator.presentedFromUpgrade = fromUpgrade

        let view = LoginLandingView(coordinator: coordinator)
        let controller = LoginLandingHostingController(rootView: view.setupDefaultEnvironment())
        controller.viewModel = coordinator

        let navController = navigationController ?? UINavigationController(rootViewController: controller)
        coordinator.navigationController = navController

        return (navigationController == nil) ? navController : controller
    }
}
