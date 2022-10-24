import SwiftUI
import MaterialComponents.MaterialBottomSheet
import PocketCastsDataModel

struct EndOfYear {
    // We'll calculate this just once
    static var isEligible: Bool {
        FeatureFlag.endOfYear && DataManager.sharedManager.isEligibleForEndOfYearStories()
    }

    func showPrompt(in viewController: UIViewController) {
        guard Self.isEligible else {
            return
        }

        let endfOfYearModalViewController = UIHostingController(rootView: EndOfYearModal().edgesIgnoringSafeArea(.all).environmentObject(Theme.sharedTheme))
        let vc = EndOfYearModalViewController()
        vc.stackView.addArrangedSubview(endfOfYearModalViewController.view)
        endfOfYearModalViewController.didMove(toParent: vc)
        let bottomSheet = MDCBottomSheetController(contentViewController: vc)

        let shapeGenerator = MDCCurvedRectShapeGenerator(cornerSize: CGSize(width: 8, height: 8))
        bottomSheet.setShapeGenerator(shapeGenerator, for: .preferred)
        bottomSheet.setShapeGenerator(shapeGenerator, for: .extended)
        bottomSheet.setShapeGenerator(shapeGenerator, for: .closed)
        bottomSheet.isScrimAccessibilityElement = true
        bottomSheet.scrimAccessibilityLabel = L10n.accessibilityDismiss

        endfOfYearModalViewController.view.backgroundColor = AppTheme.colorForStyle(.primaryUi01)

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

class EndOfYearModalViewController: UIViewController {
    let stackView = UIStackView()

    init() {
        super.init(nibName: nil, bundle: nil)
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        preferredContentSize = .init(width: .zero, height: stackView.frame.height)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
