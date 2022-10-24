import SwiftUI
import MaterialComponents.MaterialBottomSheet

/// A wrapper for `MDCBottomSheetController` to work with SwiftUI
///
class MDCSwiftUIWrapper<ContentView: View>: UIViewController {
    private let stackView = UIStackView()

    init(rootView content: ContentView) {
        super.init(nibName: nil, bundle: nil)

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
        hostingController.view.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        preferredContentSize = .init(width: .zero, height: stackView.frame.height)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Present a SwiftUI us a bottom sheet in the given VC
    static func present(_ content: ContentView, in viewController: UIViewController) {
        let wrapperController = MDCSwiftUIWrapper(rootView: content)
        let bottomSheet = MDCBottomSheetController(contentViewController: wrapperController)

        let shapeGenerator = MDCCurvedRectShapeGenerator(cornerSize: CGSize(width: 8, height: 8))
        bottomSheet.setShapeGenerator(shapeGenerator, for: .preferred)
        bottomSheet.setShapeGenerator(shapeGenerator, for: .extended)
        bottomSheet.setShapeGenerator(shapeGenerator, for: .closed)
        bottomSheet.isScrimAccessibilityElement = true
        bottomSheet.scrimAccessibilityLabel = L10n.accessibilityDismiss

        viewController.present(bottomSheet, animated: true, completion: nil)
    }
}
