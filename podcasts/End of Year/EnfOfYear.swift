import SwiftUI
import MaterialComponents.MaterialBottomSheet

struct EndOfYear {
    func showIfAvailable(in viewController: UIViewController) {
        guard FeatureFlag.endOfYear else {
            return
        }

        let endfOfYearModalViewController = UIHostingController(rootView: EndOfYearModal())
        let bottomSheet = MDCBottomSheetController(contentViewController: endfOfYearModalViewController)
        viewController.present(bottomSheet, animated: true, completion: nil)
    }
}
