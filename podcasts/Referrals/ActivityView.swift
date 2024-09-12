import SwiftUI
import UIKit

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    @Environment(\.dismiss) private var dismissAction
    private let completion: (() -> Void)?

    init(_ items: [Any], applicationActivities: [UIActivity]? = nil, completion: (() -> Void)? = nil) {
        self.activityItems = items
        self.applicationActivities = applicationActivities
        self.completion = completion
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.view.backgroundColor = .clear
        controller.completionWithItemsHandler = { _, _, _, _ in
            dismissAction()
            completion?()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {
    }
}
