import SwiftUI

/// A wrapper for `SwiftUI` views to work with UISheetPresentationController
///
class BottomSheetSwiftUIWrapper<ContentView: View>: UIViewController {
    private let stackView = UIStackView()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    let backgroundColor: UIColor?
    let backgroundStyle: ThemeStyle?

    init(rootView content: ContentView, backgroundColor: UIColor) {
        self.backgroundColor = backgroundColor
        self.backgroundStyle = nil
        super.init(nibName: nil, bundle: nil)

        setup(content: content, backgroundColor: backgroundColor)
    }

    init(rootView content: ContentView, backgroundStyle: ThemeStyle = .primaryUi01) {
        self.backgroundStyle = backgroundStyle
        self.backgroundColor = nil

        super.init(nibName: nil, bundle: nil)
        setup(content: content, backgroundStyle: backgroundStyle)
    }

    private func setup(content: ContentView, backgroundStyle: ThemeStyle? = nil, backgroundColor: UIColor? = nil) {
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
        ])

        let hostingController = UIHostingController(
            rootView: content
                .edgesIgnoringSafeArea(.all)
                .environmentObject(Theme.sharedTheme)
        )
        stackView.addArrangedSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        if let backgroundStyle {
            hostingController.view.backgroundColor = AppTheme.colorForStyle(backgroundStyle)
        } else if let backgroundColor {
            hostingController.view.backgroundColor = backgroundColor
        }
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
        preferredContentSize = .init(width: .zero, height: stackView.frame.height)

        // Reset the alpha
        view.alpha = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Present a SwiftUI us a bottom sheet in the given VC
    static func present(_ content: ContentView, in viewController: UIViewController) {
        let wrapperController = BottomSheetSwiftUIWrapper(rootView: content)
        wrapperController.presentModally(in: viewController)
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
            sheetController.detents = detents
            sheetController.prefersGrabberVisible = showingGrabber
        }

        viewController.present(self, animated: true, completion: nil)
    }
}
