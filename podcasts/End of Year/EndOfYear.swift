import SwiftUI
import MaterialComponents.MaterialBottomSheet

struct EndOfYear {
    static var finishedImage: UIImage?

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
