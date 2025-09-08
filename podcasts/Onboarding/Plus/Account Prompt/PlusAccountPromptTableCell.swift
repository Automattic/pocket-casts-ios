import SwiftUI
import UIKit
import PocketCastsUtils

class PlusAccountPromptTableCell: ThemeableCell {
//    static let reuseIdentifier: String = "PlusAccountPromptTableCell"

    private weak var model: PlusAccountPromptViewModel?

    /// Listen for size changes from the view so we can adjust the table size
    var contentSizeUpdated: ((CGSize) -> Void)? = nil

    init(reuseIdentifier: String?, model: PlusAccountPromptViewModel) {
        self.model = model

        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        let view: UIView
        if FeatureFlag.newOnboardingUpgrade.enabled {
            view = UpgradeBannerView(viewModel: UpgradeAccountViewModel(upgradeTier: .plus, selectedProduct: .yearly, viewSource: .profile, flowSource: .accountScreen), onSubscribeTap: {
                let controller = OnboardingFlow.shared.begin(flow: .plusAccountUpgrade, in: model.parentController, source: .profile, context: nil)
                model.parentController?.present(controller, animated: true)
            }).themedUIView
        } else if FeatureFlag.newAccountUpgradePromptFlow.enabled {
            let _ = OnboardingFlow.shared.begin(flow: .plusAccountUpgrade, in: model.parentController, source: .profile, context: nil)
            view = UpgradePrompt(viewModel: PlusLandingViewModel(source: .accountScreen, viewSource: .profile)) { [weak self] size in
                self?.contentSizeUpdated?(size)
            }.themedUIView
        } else {
            view = PlusAccountUpgradePrompt(viewModel: model, contentSizeUpdated: { [weak self] size in
                self?.contentSizeUpdated?(size)
            }).themedUIView
        }
        view.backgroundColor = .clear

        contentView.addSubview(view)

        layoutIfNeeded()

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        view.layoutIfNeeded()
        if FeatureFlag.newOnboardingUpgrade.enabled {
            self.separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)
            self.style = .primaryUi03
        }

    }

    // Update the model's parent so we can present the modal
    func updateParent(_ controller: UIViewController) {
        model?.parentController = controller
        model?.source = .profile
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard FeatureFlag.newOnboardingUpgrade.enabled else {
            return
        }

        for view in self.subviews {
            if view == self.contentView {
                continue
            }
            if (view.bounds.size.width == self.bounds.size.width) && (view.frame.origin.y == 0) {
                view.isHidden = true
            }
        }
    }
}
