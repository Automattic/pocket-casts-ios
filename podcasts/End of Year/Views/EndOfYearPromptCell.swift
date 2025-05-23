import Foundation
import SwiftUI

class EndOfYearPromptCell: ThemeableCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let viewModel: EndOfYearCard.ViewModel

        switch EndOfYear.currentYear {
        case .y2022:
            fatalError("Shouldn't reach this point")
        case .y2023:
            viewModel = .init(title: L10n.eoyTitle, description: L10n.eoyCardDescription, imageName: "23_small", imagePadding: 20)
        case .y2024:
            viewModel = .init(title: L10n.playback2024FeatureTitle, description: L10n.playback2024FeatureDescription, imageName: "playback-24", imagePadding: 60)
        }

        let childView = UIHostingController(rootView: EndOfYearCard(viewModel: viewModel)
            .environmentObject(Theme.sharedTheme))
        childView.view.backgroundColor = .clear
        contentView.addSubview(childView.view)

        childView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childView.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            childView.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            childView.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            childView.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
