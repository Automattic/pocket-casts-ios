import UIKit

class PlusAccountPromptViewModel: PlusPricingInfoModel {
    weak var parentController: UIViewController? = nil
    var source: Source = .unknown

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

    enum Source: String {
        case unknown
        case accountDetails = "account_details"
        case plusDetails = "plus_details"
    }
}

private extension PlusAccountPromptViewModel {
    func showModal() {
        guard let parentController else { return }
        let controller = OnboardingFlow.shared.begin(flow: .plusAccountUpgrade, in: parentController, source: source.rawValue)

        controller.presentModally(in: parentController)
    }

    func showError() {
        SJUIUtils.showAlert(title: L10n.plusUpgradeNoInternetTitle, message: L10n.plusUpgradeNoInternetMessage, from: parentController)
    }
}
