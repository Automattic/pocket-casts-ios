import SwiftUI
import UIKit

class PlusAccountPromptTableCell: ThemeableCell {
    static let reuseIdentifier: String = "PlusAccountPromptTableCell"

    private let model: PlusAccountPromptViewModel = PlusAccountPromptViewModel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let view = PlusAccountUpgradePrompt(viewModel: model).setupDefaultEnvironment()
        let controller = UIHostingController(rootView: view)
        contentView.addSubview(controller.view)

        layoutIfNeeded()

        controller.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        controller.view.layoutIfNeeded()
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
