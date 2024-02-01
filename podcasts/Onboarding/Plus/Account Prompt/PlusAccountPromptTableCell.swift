import SwiftUI
import UIKit

class PlusAccountPromptTableCell: ThemeableCell {
//    static let reuseIdentifier: String = "PlusAccountPromptTableCell"

    private let model = PlusAccountPromptViewModel()

    /// Listen for size changes from the view so we can adjust the table size
    var contentSizeUpdated: ((CGSize) -> Void)? = nil

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

//        let view = UpgradePrompt(viewModel: PlusLandingViewModel(source: .upsell)) { [weak self] size in
//            self?.contentSizeUpdated?(size)
//        }.themedUIView

        let view = PlusAccountUpgradePrompt(viewModel: model, contentSizeUpdated: { [weak self] size in
            self?.contentSizeUpdated?(size)
        }).themedUIView
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
    }

    // Update the model's parent so we can present the modal
    func updateParent(_ controller: UIViewController) {
        model.parentController = controller
        model.source = .accountDetails
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
