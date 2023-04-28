import Foundation
import PocketCastsServer
import SwiftUI
import PocketCastsDataModel

class LoginCoordinator: NSObject, OnboardingModel {
    weak var navigationController: UINavigationController? = nil
    let headerImages: [LoginHeaderImage]
    var continuePurchasing: Constants.ProductInfo? = nil

    private var socialLogin: SocialLogin?
    private var socialAuthProvider: SocialAuthProvider?

    private var progressAlert: ShiftyLoadingAlert?

    /// Used to determine which screen after login to show to the user
    private var newAccountCreated = false

    override init() {
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
        socialAuthProvider = nil
        OnboardingFlow.shared.track(.setupAccountButtonTapped, properties: ["button": "sign_in"])
        let controller = SyncSigninViewController()
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }

    func signUpTapped() {
        socialAuthProvider = nil
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
    @MainActor
    func signIn(with provider: SocialAuthProvider) {
        guard let navigationController else {
            return
        }

        socialAuthProvider = provider

        Analytics.track(.ssoStarted, properties: ["source": provider])

        socialLogin = SocialLoginFactory.provider(for: provider, from: navigationController)

        Task {
            progressAlert = SyncLoadingAlert()
            do {
                // First get token
                try await self.socialLogin?.getToken()

                // If token is returned, perform login on our servers
                await withUnsafeContinuation { continuation in
                    progressAlert?.showAlert(navigationController, hasProgress: false) {
                        continuation.resume()
                    }
                }

                let response = try await self.socialLogin?.login()
                newAccountCreated = response?.isNewAccount ?? false

                if !newAccountCreated {
                    Analytics.track(.userSignedIn, properties: ["source": provider])
                }

                listenToSync()
            } catch {
                progressAlert?.hideAlert(false) {
                    self.showError(error)
                }
            }
        }
    }
}

extension LoginCoordinator: SyncSigninDelegate, CreateAccountDelegate {
    private func listenToSync() {
        NotificationCenter.default.addObserver(self, selector: #selector(syncCompleted), name: ServerNotifications.syncCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(syncCompleted), name: ServerNotifications.syncFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(syncCompleted), name: ServerNotifications.podcastRefreshFailed, object: nil)
    }

    @objc private func syncCompleted() {
         DispatchQueue.main.async {
             self.progressAlert?.hideAlert(false)
             self.progressAlert = nil

             if self.newAccountCreated {
                 self.handleAccountCreated()
             } else {
                 self.signingProcessCompleted()
             }
         }
     }

    func signingProcessCompleted() {
        // Due to connection issues this might be called even if the user didn't actually
        // signed in. So we make sure the user is actually logged in.
        guard SyncManager.isUserLoggedIn() else {
            return
        }

        let shouldDismiss = OnboardingFlow.shared.currentFlow.shouldDismiss || (SubscriptionHelper.hasActiveSubscription() && continuePurchasing == nil)

        if shouldDismiss {
            handleDismiss()
            return
        }

        goToPlus(from: .login)
    }

    func handleAccountCreated() {
        Analytics.track(.userAccountCreated, properties: ["source": socialAuthProvider ?? "password"])

        if OnboardingFlow.shared.currentFlow.shouldDismiss {
            handleDismiss()
            return
        }

        goToPlus(from: .accountCreated)
    }

    private func handleDismiss() {
        navigationController?.dismiss(animated: true) {
            DispatchQueue.main.async {
                OnboardingFlow.shared.reset()
            }
        }
    }

    func showError(_ error: Error) {
        guard (error as? SocialLoginError) != .canceled else {
            return
        }

        Analytics.track(.userSignInFailed, properties: ["source": socialAuthProvider ?? "password", "error_code": (error as NSError).code])
        SJUIUtils.showAlert(title: L10n.accountSsoFailed, message: nil, from: navigationController)
    }

    private func goToPlus(from source: PlusLandingViewModel.Source) {
        // Update the flow to make sure the correct analytics source is passed on
        OnboardingFlow.shared.updateAnalyticsSource(source == .login ? "login" : "account_created")

        let controller = PlusLandingViewModel.make(in: navigationController,
                                                   from: source,
                                                   continuePurchasing: continuePurchasing)
        navigationController?.setViewControllers([controller], animated: true)
    }
}

// MARK: - Helpers

extension LoginCoordinator {
    static func make(in navigationController: UINavigationController? = nil, continuePurchasing: Constants.ProductInfo? = nil) -> UIViewController {
        let coordinator = LoginCoordinator()
        coordinator.continuePurchasing = continuePurchasing

        let view = LoginLandingView(coordinator: coordinator)
        let controller = LoginLandingHostingController(rootView: view.setupDefaultEnvironment())
        controller.viewModel = coordinator

        let navController = navigationController ?? UINavigationController(rootViewController: controller)
        coordinator.navigationController = navController

        return (navigationController == nil) ? navController : controller
    }
}
