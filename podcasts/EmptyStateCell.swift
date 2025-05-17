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
        if #available(iOS 16.0, *) {
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
        } else {
            let view = EmptyStateView(
                title: title,
                message: message,
                icon: icon,
                actions: actions,
                style: .defaultStyle
            )
            let uiView = view.uiView
            uiView.translatesAutoresizingMaskIntoConstraints = false
            uiView.backgroundColor = .clear
            contentView.addSubview(uiView)
            NSLayoutConstraint.activate([
                contentView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: uiView.leadingAnchor),
                contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: uiView.trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: uiView.bottomAnchor),
                contentView.topAnchor.constraint(equalTo: uiView.topAnchor)
            ])
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
    override func setEditing(_ editing: Bool, animated: Bool) {}
}
