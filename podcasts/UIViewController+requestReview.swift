import UIKit
import StoreKit

extension UIViewController {
    func requestReview() {
        guard Settings.reviewRequestDates().count == 0 else { return }

        Task { @MainActor [weak self] in
            // Delay for two seconds to avoid interrupting the person using the app.
            // Use the equation n * 10^9 to convert seconds to nanoseconds.
            try? await Task.sleep(nanoseconds: UInt64(2e9))
            if let windowScene = self?.view.window?.windowScene,
               self?.navigationController?.topViewController == self {
                SKStoreReviewController.requestReview(in: windowScene)
                Settings.addReviewRequested()
           }
        }
    }
}
