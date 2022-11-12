import UIKit
import SwiftUI

class EventDelegateHostingController<Content: View>: UIHostingController<Content> where Content: View {
    let coordinator: ViewEventCoordinator

    init(rootView: Content, coordinator: ViewEventCoordinator) {
        self.coordinator = coordinator
        super.init(rootView: rootView)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        coordinator.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        coordinator.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        coordinator.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        coordinator.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        coordinator.viewDidDisappear(animated)
    }
}

// MARK: - ViewEventCoordinator

protocol ViewEventCoordinator {
    func viewDidLoad()
    func viewWillAppear(_ animated: Bool)
    func viewDidAppear(_ animated: Bool)
    func viewWillDisappear(_ animated: Bool)
    func viewDidDisappear(_ animated: Bool)
}

extension ViewEventCoordinator {
    func viewDidLoad() {}
    func viewWillAppear(_ animated: Bool) {}
    func viewDidAppear(_ animated: Bool) {}
    func viewWillDisappear(_ animated: Bool) {}
    func viewDidDisappear(_ animated: Bool) {}
}
