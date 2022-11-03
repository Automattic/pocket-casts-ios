import SwiftUI
import PocketCastsServer
import MaterialComponents.MaterialBottomSheet
import PocketCastsDataModel

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
            showStories(in: viewController)

        // If the user has seen the prompt, and chosen to login, but then has cancelled out of the flow without logging in,
        // When this code is ran from MainTabController viewDidAppear we will still be in the waiting state
        // reset the state to the default to restart the process over again
        case .waitingForLogin:
            Self.state = .showModalIfNeeded
        }
    }

    func showStories(in viewController: UIViewController) {
        guard FeatureFlag.endOfYear else {
            return
        }

        if Self.requireAccount && !SyncManager.isUserLoggedIn() {
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
    }

    func share(asset: @escaping () -> Any, onDismiss: (() -> Void)? = nil) {
        let presenter = SceneHelper.rootViewController()?.presentedViewController

        let imageToShare = [StoryShareableProvider()]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = presenter?.view

        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            onDismiss?()
        }

        presenter?.present(activityViewController, animated: true) {
            // After the share sheet is presented we take the snapshot
            // This action needs to happen on the main thread because
            // the view needs to be rendered.
            StoryShareableProvider.generatedItem = asset() as? UIImage
        }
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
