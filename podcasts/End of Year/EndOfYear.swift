import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

enum EndOfYearPresentationSource: String {
    case modal = "modal"
    case profile = "profile"
    case userLogin = "user_login"
}

struct EndOfYear {
    enum Year: CaseIterable {
        case y2022
        case y2023
        case y2024

        var modelType: StoryModel.Type? {
            switch self {
            case .y2022:
                nil
            case .y2023:
                EndOfYear2023StoriesModel.self
            case .y2024:
                EndOfYear2024StoriesModel.self
            }
        }

        var year: Int? {
            modelType?.year
        }
    }

    static var isEligible: Bool { eligibilityChecker?.isEligible ?? false }

    static var shouldShowBadge: Bool {
        guard let year = currentYear.year else { return false }
        return Settings.showBadgeForEndOfYear(year)
    }

    // Eligibility checker to manage the `isEligible` state
    private static var eligibilityChecker: EligibilityChecker? = {
        if let year = currentYear.year {
            .init(year: year)
        } else {
            nil
        }
    }()

    /// Internal state machine to determine how we should react to login changes
    /// and when to show the modal vs go directly to the stories
    private static var state: EndOfYearState = .showModalIfNeeded

    static var currentYear: Year {
        if FeatureFlag.endOfYear2024.enabled {
            return .y2024
        } else if FeatureFlag.endOfYear.enabled {
            return .y2023
        } else {
            return .y2022
        }
    }

    private(set) var storyModelType: StoryModel.Type?

    static var requireAccount: Bool = Settings.endOfYearRequireAccount {
        didSet {
            // If registration is not needed anymore and this user is logged out
            // Show the prompt again.
            if let year = currentYear.year, oldValue && !requireAccount && !SyncManager.isUserLoggedIn() {
                Settings.setHasShownModalForEndOfYear(false, year: year)
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

        storyModelType = Self.currentYear.modelType
    }

    func showPrompt(in viewController: UIViewController) {
        guard Self.isEligible, let storyModelType, !Settings.hasShownModalForEndOfYear(storyModelType.year) else {
            return
        }

        let viewModel: EndOfYearModal.ViewModel

        switch Self.currentYear {
        case .y2022:
            fatalError("Shouldn't reach this")
        case .y2023:
            viewModel = .init(buttonTitle: L10n.eoyViewYear, description: L10n.eoyDescription, backgroundImageName: "modal_cover")
        case .y2024:
            viewModel = .init(buttonTitle: L10n.playback2024ViewYear, description: L10n.playback2024Description, backgroundImageName: "playback-featured")
        }

        BottomSheetSwiftUIWrapper.present(EndOfYearModal(year: storyModelType.year, model: viewModel), in: viewController)
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
        guard let storyModelType else { return }

        if Self.requireAccount && !SyncManager.isUserLoggedIn() {
            Self.state = .waitingForLogin

            let onboardingController = OnboardingFlow.shared.begin(flow: .endOfYear)
            viewController.present(onboardingController, animated: true)
            return
        }

        // Don't show the prompt if the user is has already viewed the stories.
        Settings.setHasShownModalForEndOfYear(true, year: storyModelType.year)

        let model = storyModelType.init()

        let storiesViewController = StoriesHostingController(rootView: StoriesView(dataSource: EndOfYearStoriesDataSource(model: model)).padding(storiesPadding))
        storiesViewController.view.backgroundColor = .black
        storiesViewController.modalPresentationStyle = presentationMode

        // Define the size of the stories view for iPad
        if UIDevice.current.isiPad() {
            storiesViewController.preferredContentSize = .init(width: 370, height: 693)
        }

        viewController.present(storiesViewController, animated: true, completion: nil)
        Analytics.track(.endOfYearStoriesShown, properties: ["source": source.rawValue])
    }

    static func share(assets: [Any], storyIdentifier: String = "unknown", onDismiss: (() -> Void)? = nil) {
        let presenter = FeatureFlag.newPlayerTransition.enabled ? SceneHelper.rootViewController() : SceneHelper.rootViewController()?.presentedViewController

        let fakeViewController = FakeViewController()
        fakeViewController.onDismiss = onDismiss
        fakeViewController.modalPresentationStyle = .overFullScreen

        let activityViewController = UIActivityViewController(activityItems: assets, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = presenter?.view

        activityViewController.completionWithItemsHandler = { activity, success, _, _ in
            if !success && activity == nil {
                fakeViewController.dismiss(animated: false)
            }

            if let activity, success {
                Analytics.track(.endOfYearStoryShared, properties: ["activity": activity.rawValue, "story": storyIdentifier])
                fakeViewController.dismiss(animated: false)
            }
        }

        // Present the fake view controller first to avoid issues with stories being dismissed
        presenter?.present(fakeViewController, animated: false) { [weak fakeViewController] in
            // Present the share sheet
            fakeViewController?.present(activityViewController, animated: true) {
                // After the share sheet is presented we take the snapshot
                // This action needs to happen on the main thread because
                // the view needs to be rendered.
                StoryShareableProvider.shared.snapshot()
            }
        }
    }

    func resetStateIfNeeded() {
        // When a user logs in (or creates an account) we mark the EOY modal as not
        // shown to show it again.
        if Self.state == .showModalIfNeeded, let storyModelType {
            Settings.setHasShownModalForEndOfYear(false, year: storyModelType.year)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Dark overlay background for iPad
        presentationController?.containerView?.backgroundColor = .black.withAlphaComponent(0.8)
    }
}

private enum EndOfYearState {
    case showModalIfNeeded, waitingForLogin, loggedIn
}

/// When selecting "Save Image" on the share sheet on iOS 15
/// the sheets dismisses itself AND the stories.
/// We don't want that, so we have this fake view controller to
/// be dismissed instead.
///
/// The issue doesn't affect iOS 14 and 16, but given this fix
/// don't interfere with them, we also use it for 14/16.
private class FakeViewController: UIViewController {
    var onDismiss: (() -> Void)?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDismiss?()
    }
}

extension EndOfYear {
    static let eoyEligibilityDidChange = NSNotification.Name(rawValue: "eoyEligibilityDidChange")

    private class EligibilityChecker {
        deinit {
            stopListening()
        }

        var isEligible = false

        private let notificationCenter: NotificationCenter
        private var notifications: [NSObjectProtocol] = []

        private let year: Int

        init(year: Int, notificationCenter: NotificationCenter = .default) {
            self.year = year

            self.notificationCenter = notificationCenter

            startListening()
            update()
        }

        private func startListening() {
            // The notifications to update the state for
            let notifications: [Notification.Name] = [
                // Check after a sync succeeds or the user logs into an account
                ServerNotifications.syncCompleted,
                .userSignedIn,

                // Check as the user is listening to episodes
                Constants.Notifications.playbackPaused,
                Constants.Notifications.playbackEnded,
                Constants.Notifications.playbackTrackChanged
            ]

            self.notifications = notifications.map {
                notificationCenter.addObserver(forName: $0, object: nil, queue: .main) { [weak self] notification in
                    self?.update()
                }
            }
        }

        private func stopListening() {
            notifications.forEach { notificationCenter.removeObserver($0) }
            notifications.removeAll()
        }

        private func update() {
            isEligible = DataManager.sharedManager.isEligibleForEndOfYearStories(in: year)

            // Let others know this changed
            if isEligible {
                notificationCenter.post(name: EndOfYear.eoyEligibilityDidChange, object: nil)

                // We don't need to check eligibility anymore
                stopListening()
            }
        }
    }
}
