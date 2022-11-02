import SwiftUI
import PocketCastsServer
import MaterialComponents.MaterialBottomSheet
import PocketCastsDataModel

enum EndOfYearPresentationSource: String {
    case modal = "modal"
    case profile = "profile"
}

struct EndOfYear {
    // We'll calculate this just once
    static var isEligible: Bool {
        FeatureFlag.endOfYear && DataManager.sharedManager.isEligibleForEndOfYearStories()
    }

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

    func showStories(in viewController: UIViewController, from source: EndOfYearPresentationSource) {
        guard FeatureFlag.endOfYear else {
            return
        }

        if Self.requireAccount && !SyncManager.isUserLoggedIn() {
            let controller = ProfileIntroViewController()
            controller.infoLabelText = L10n.eoyCreateAccountToSee
            viewController.present(controller, animated: true)
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
}

class StoriesHostingController<ContentView: View>: UIHostingController<ContentView> {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
