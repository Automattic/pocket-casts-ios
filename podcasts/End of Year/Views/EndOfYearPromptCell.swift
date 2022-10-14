import Foundation
import SwiftUI

class EndOfYearPromptCell: ThemeableCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let childView = UIHostingController(rootView: EndOfYearCard())
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
