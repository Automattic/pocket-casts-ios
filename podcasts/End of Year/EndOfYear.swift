import SwiftUI
import MaterialComponents.MaterialBottomSheet

struct EndOfYear {
    func showPrompt(in viewController: UIViewController) {
        guard FeatureFlag.endOfYear else {
            return
        }

        let endfOfYearModalViewController = UIHostingController(rootView: EndOfYearModal().environmentObject(Theme.sharedTheme))
        let bottomSheet = MDCBottomSheetController(contentViewController: endfOfYearModalViewController)
        viewController.present(bottomSheet, animated: true, completion: nil)
    }

    func showStories(in viewController: UIViewController) {
        guard FeatureFlag.endOfYear else {
            return
        }

        let storiesViewController = StoriesHostingController(rootView: StoriesView(dataSource: EndOfYearStoriesDataSource()))
        storiesViewController.view.backgroundColor = .black
        storiesViewController.modalPresentationStyle = .fullScreen
        viewController.present(storiesViewController, animated: true, completion: nil)
    }

    func share(view: any View, onDismiss: (() -> Void)? = nil) {
        let presenter = SceneHelper.rootViewController()?.presentedViewController

        let imageToShare = [view.snapshot()]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = presenter?.view
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]

        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            onDismiss?()
        }

        presenter?.present(activityViewController, animated: true, completion: nil)
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
