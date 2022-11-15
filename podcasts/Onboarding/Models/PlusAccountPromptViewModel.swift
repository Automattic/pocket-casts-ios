import UIKit

class PlusAccountPromptViewModel: PlusPricingInfoModel {
    weak var parentController: UIViewController? = nil

    func upgradeTapped() {
        guard let parentController else { return }
        let controller = PlusPurchaseModel.make(in: parentController)
        controller.presentModally(in: parentController)
    }
}
