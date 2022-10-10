import SwiftUI
import MaterialComponents.MaterialBottomSheet

struct EndOfYear {
    func showPrompt(in viewController: UIViewController) {
        guard FeatureFlag.endOfYear else {
            return
        }

        let endfOfYearModalViewController = UIHostingController(rootView: EndOfYearModal().environmentObject(Theme.sharedTheme))
        let bottomSheet = MDCBottomSheetController(contentViewController: endfOfYearModalViewController)
        viewController.present(bottomSheet, animated: true, completion: nil)
    }
}
