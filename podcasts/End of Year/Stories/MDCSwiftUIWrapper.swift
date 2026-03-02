import SwiftUI

/// A wrapper for `SwiftUI` views to work with UISheetPresentationController
///
class BottomSheetSwiftUIWrapper<ContentView: View>: UIViewController, UISheetPresentationControllerDelegate {
    private let stackView = UIStackView()
    private var customDetentHeight: CGFloat = 0

    private weak var hostingController: UIHostingController<ContentView>?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    let backgroundColor: UIColor?
    let backgroundStyle: ThemeStyle?
    let dismissCallback: (()->())?

    init(rootView content: ContentView, backgroundColor: UIColor, dismissCallback: (()->())? = nil) {
        self.backgroundColor = backgroundColor
        self.backgroundStyle = nil
        self.dismissCallback = dismissCallback
        super.init(nibName: nil, bundle: nil)

        setup(content: content, backgroundColor: backgroundColor)
    }

    init(rootView content: ContentView, backgroundStyle: ThemeStyle = .primaryUi01, dismissCallback: (()->())? = nil) {
        self.backgroundStyle = backgroundStyle
        self.backgroundColor = nil
        self.dismissCallback = dismissCallback
        super.init(nibName: nil, bundle: nil)
        setup(content: content, backgroundStyle: backgroundStyle)
    }

    private func setup(content: ContentView, backgroundStyle: ThemeStyle? = nil, backgroundColor: UIColor? = nil) {
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])

        let hostingController = UIHostingController(
            rootView: content
                .edgesIgnoringSafeArea(.all)
                .environmentObject(Theme.sharedTheme)
        )
        hostingController.sizingOptions = [.intrinsicContentSize]
        addChild(hostingController)
        stackView.addArrangedSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        if let backgroundStyle {
            hostingController.view.backgroundColor = AppTheme.colorForStyle(backgroundStyle)
        } else if let backgroundColor {
            hostingController.view.backgroundColor = backgroundColor
        }

        updatePreferredContentSize()
    }

    private func updatePreferredContentSize() {
        hostingController?.view.layoutIfNeeded()
        stackView.layoutIfNeeded()

        let fittingSize = stackView.systemLayoutSizeFitting(
            CGSize(width: UIScreen.main.bounds.width, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )

        customDetentHeight = fittingSize.height
        preferredContentSize = CGSize(width: fittingSize.width, height: fittingSize.height)
    }

    override func loadView() {
        if let backgroundStyle {
            let themeView = ThemeableView()
            themeView.style = backgroundStyle
            view = themeView
        } else if let backgroundColor {
            view = UIView()
            view.backgroundColor = backgroundColor
        }

        // Prevents a flicker from happening just before the view appears
        view.alpha = 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePreferredContentSize()
        view.alpha = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Present a SwiftUI view as a bottom sheet in the given VC. If `autoSize` is `true`, a custom detent will be calculated based on the view size
    static func present(_ content: ContentView, autoSize: Bool = false, showingGrabber: Bool = false, in viewController: UIViewController, dismissCallback: (()->())? = nil) {
        let wrapperController = BottomSheetSwiftUIWrapper(rootView: content, dismissCallback: dismissCallback)
        if autoSize {
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                wrapperController.updatePreferredContentSize()
                return wrapperController.customDetentHeight
            }
            wrapperController.presentModally(in: viewController, detents: [customDetent], showingGrabber: showingGrabber)
        } else {
            wrapperController.presentModally(in: viewController, showingGrabber: showingGrabber)
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.dismissCallback?()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            if let sheetController = sheetPresentationController {
                updatePreferredContentSize()
                sheetController.animateChanges {
                    sheetController.invalidateDetents()
                }
            }
        }
    }

}

extension UIViewController {
    func presentModally(
        in viewController: UIViewController,
        detents: [UISheetPresentationController.Detent] = [.medium()],
        // Grabber defaults to false as most pocketcasts views implement their own.
        showingGrabber: Bool = false
    ) {
        if let sheetController = self.sheetPresentationController {
            // Create custom detent based on content size
            sheetController.detents = detents
            if let sheetDelegate = self as? UISheetPresentationControllerDelegate {
                sheetController.delegate = sheetDelegate
            }
            sheetController.prefersGrabberVisible = showingGrabber
            sheetController.preferredCornerRadius = 10

            // Prevent sheet from being dismissed by dragging down
            sheetController.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        viewController.present(self, animated: true, completion: nil)
    }
}
