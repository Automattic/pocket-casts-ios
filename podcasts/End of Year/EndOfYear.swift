import SwiftUI
import PocketCastsServer
import MaterialComponents.MaterialBottomSheet
import PocketCastsDataModel

enum EndOfYearPresentationSource: String {
    case modal = "modal"
    case profile = "profile"
    case userLogin = "user_login"
}

struct EndOfYear {
    // We'll calculate this just once
    static var isEligible: Bool {
        FeatureFlag.endOfYear && DataManager.sharedManager.isEligibleForEndOfYearStories()
    }

    /// Internal state machine to determine how we should react to login changes
    /// and when to show the modal vs go directly to the stories
    private static var state: EndOfYearState = .showModalIfNeeded

    static var requireAccount: Bool = Settings.endOfYearRequireAccount {
        didSet {
            // If registration is not needed anymore and this user is logged out
            // Show the prompt again.
            if oldValue && !requireAccount && !SyncManager.isUserLoggedIn() {
                Settings.endOfYearModalHasBeenShown = false
                NotificationCenter.postOnMainThread(notification: .eoyRegistrationNotRequired, object: nil)
            }
        }
    }

    var presentationMode: UIModalPresentationStyle {
        UIDevice.current.isiPad() ? .formSheet : .fullScreen
    }

    var storiesPadding: EdgeInsets {
        .init(top: 0, leading: 0, bottom: UIDevice.current.isiPad() ? 5 : 0, trailing: 0)
    }

    init() {
        Self.requireAccount = Settings.endOfYearRequireAccount
    }

    func showPrompt(in viewController: UIViewController) {
        guard Self.isEligible, !Settings.endOfYearModalHasBeenShown else {
            return
        }

        MDCSwiftUIWrapper.present(EndOfYearModal(), in: viewController)
    }

    func showPromptBasedOnState(in viewController: UIViewController) {
        switch Self.state {

        // If we're in the default state, then check to see if we should show the prompt
        case .showModalIfNeeded:
            showPrompt(in: viewController)

        // If we were in the waiting state, but the user has logged in, then show stories
        case .loggedIn:
            Self.state = .showModalIfNeeded
            showStories(in: viewController, from: .userLogin)

        // If the user has seen the prompt, and chosen to login, but then has cancelled out of the flow without logging in,
        // When this code is ran from MainTabController viewDidAppear we will still be in the waiting state
        // reset the state to the default to restart the process over again
        case .waitingForLogin:
            Self.state = .showModalIfNeeded
        }
    }

    func showStories(in viewController: UIViewController, from source: EndOfYearPresentationSource) {
        guard FeatureFlag.endOfYear else {
            return
        }

        if Self.requireAccount && !SyncManager.isUserLoggedIn() {
            Self.state = .waitingForLogin

            let profileIntroController = ProfileIntroViewController()
            profileIntroController.infoLabelText = L10n.eoyCreateAccountToSee
            let navigationController = UINavigationController(rootViewController: profileIntroController)
            navigationController.modalPresentationStyle = .fullScreen
            viewController.present(navigationController, animated: true)
            return
        }

        let storiesViewController = StoriesHostingController(rootView: StoriesView(dataSource: EndOfYearStoriesDataSource()).padding(storiesPadding))
        storiesViewController.view.backgroundColor = .black
        storiesViewController.modalPresentationStyle = presentationMode

        // Define the size of the stories view for iPad
        if UIDevice.current.isiPad() {
            storiesViewController.preferredContentSize = .init(width: 370, height: 693)
        }

        viewController.present(storiesViewController, animated: true, completion: nil)
        Analytics.track(.endOfYearStoriesShown, properties: ["source": source.rawValue])
    }

    func share(assets: [Any], storyIdentifier: String = "unknown", onDismiss: (() -> Void)? = nil) {
        let presenter = SceneHelper.rootViewController()?.presentedViewController

        let activityViewController = UIActivityViewController(activityItems: assets, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = presenter?.view

        activityViewController.completionWithItemsHandler = { activity, success, _, _ in
            if !success && activity == nil {
                onDismiss?()
            }

            if let activity, success {
                Analytics.track(.endOfYearStoryShared, properties: ["activity": activity.rawValue, "story": storyIdentifier])
                onDismiss?()
            }
        }

        presenter?.present(activityViewController, animated: true) {
            // After the share sheet is presented we take the snapshot
            // This action needs to happen on the main thread because
            // the view needs to be rendered.
            StoryShareableProvider.shared.snapshot()
        }
    }

    func resetStateIfNeeded() {
        // When a user logs in (or creates an account) we mark the EOY modal as not
        // shown to show it again.
        if Self.state == .showModalIfNeeded {
            Settings.endOfYearModalHasBeenShown = false
            return
        }

        guard Self.state == .waitingForLogin else { return }

        // If we're in the waiting for login state (the user has seen the prompt, and chosen to login)
        // Update the current state based on whether the user is logged in or not
        // If the user did not login, then just reset the state to the default showModalIfNeeded
        Self.state = SyncManager.isUserLoggedIn() ? .loggedIn : .showModalIfNeeded
    }
}

class StoriesHostingController<ContentView: View>: UIHostingController<ContentView> {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}

private enum EndOfYearState {
    case showModalIfNeeded, waitingForLogin, loggedIn
}
