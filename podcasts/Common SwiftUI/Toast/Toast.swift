import Foundation

/// 🍞 Toast - A lightweight way to display informative overlay messages
///
/// Usage:
///
///     // Message only
///     Toast.show("Hello World!")
///
///     // Message with button
///     Toast.show("Hello", actions: [.init(title: "World", action: {
///          print("Hello World!")
///     })])
///
class Toast {
    private static var shared = Toast()

    /// Retain the visible window
    private var window: UIWindow? = nil

    /// Display the toast message with the given title and actions
    static func show<Style: ToastTheme>(_ title: String, actions: [Action]? = nil, dismissAfter: TimeInterval = 5.0, theme: Style = .defaultTheme) {
        // Hide any active toasts
        shared.toastDismissed()

        guard let scene = SceneHelper.connectedScene() else { return }

        let viewModel = ToastViewModel(coordinator: shared, title: title, actions: actions, dismissTime: dismissAfter)
        let view = ToastView(viewModel: viewModel, style: theme)
        let controller = ThemedHostingController(rootView: view)

        let window = ToastWindow(windowScene: scene, viewModel: viewModel, controller: controller)

        window.makeKeyAndVisible()
        shared.window = window
    }

    struct Action: Identifiable {
        let title: String
        let action: () -> Void

        var id: String { title }
    }
}

// MARK: - ToastCoordinator

extension Toast: ToastCoordinator {
    func toastDismissed() {
        Self.shared.window?.resignKey()
        Self.shared.window = nil
    }
}

// MARK: - ToastWindow

/// This is a UIWindow subclass that allows passthrough events but also interaction with our SwiftUI toast view
/// The window overrides hitTest which asks the view model if the event point is within the view
private class ToastWindow: UIWindow {
    private weak var viewModel: ToastViewModel?

    init(windowScene: UIWindowScene, viewModel: ToastViewModel, controller: UIViewController) {
        self.viewModel = viewModel

        super.init(windowScene: windowScene)

        controller.view.backgroundColor = .clear
        rootViewController = controller
        windowLevel = .alert
        backgroundColor = .clear
    }

    // MARK: - Overridden

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        viewModel?.hitTest(point) ?? false ? super.hitTest(point, with: event) : nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
