import UIKit

class PlusAccountPromptViewModel: PlusPricingInfoModel {
    weak var parentController: UIViewController? = nil

    func upgradeTapped() {
        loadPrices {
            switch self.priceAvailability {
            case .available:
                self.showModal()
            case .failed:
                self.showError()
            default:
                break
            }
        }
    }
}

private extension PlusAccountPromptViewModel {
    func showModal() {
        guard let parentController else { return }
        let controller = OnboardingFlow.shared.begin(flow: .plusAccountUpgrade, in: parentController)
        controller.presentModally(in: parentController)
    }

    func showError() {
        SJUIUtils.showAlert(title: L10n.plusUpgradeNoInternetTitle, message: L10n.plusUpgradeNoInternetMessage, from: parentController)
    }
}
