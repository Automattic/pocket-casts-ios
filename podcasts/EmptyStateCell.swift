import SwiftUI

class EmptyStateCell: UITableViewCell {
    static let reuseIdentifier = "EmptyStateCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, message: String? = nil, icon: (() -> Image)? = nil, actions: [EmptyStateAction] = []) {
        self.contentConfiguration = UIHostingConfiguration {
            EmptyStateView(
                title: title,
                message: message,
                icon: icon,
                actions: actions,
                style: .defaultStyle
            )
        }
        .margins(.horizontal, 16)
        .margins(.vertical, 8)
    }
}
