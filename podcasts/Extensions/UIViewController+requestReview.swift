import StoreKit
import UIKit

extension UIViewController {
    /// Request a App Store review from the user
    /// Right now, this method only allow requesting it once per user
    ///
    /// - Parameters:
    ///     - delay: The number of seconds this function will wait before showing
    ///     the modal.
    func requestReview(delay: Double) {
        guard Settings.reviewRequestDates().count == 0 else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            // Delay for one second to avoid interrupting the person using the app.
            // Use the equation n * 10^9 to convert seconds to nanoseconds.
            try? await Task.sleep(nanoseconds: UInt64(delay * pow(10.0, 9.0)))
            if let windowScene = self.view.window?.windowScene,
               self.navigationController?.topViewController == self {
                SKStoreReviewController.requestReview(in: windowScene)
                Settings.addReviewRequested()
                Analytics.track(.appStoreReviewRequested, properties: ["source": NSStringFromClass(self.classForCoder)])
            }
        }
    }
}
