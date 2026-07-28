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

    func configure<Style: EmptyStateViewStyle>(title: String, message: String? = nil, icon: (() -> Image)? = nil, style: Style = DefaultEmptyStateStyle.defaultStyle, actions: [EmptyStateAction] = []) {
        self.contentConfiguration = UIHostingConfiguration {
            VStack {
                EmptyStateView(
                    title: title,
                    message: message,
                    icon: icon,
                    actions: actions,
                    style: style
                )
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .margins(.horizontal, 16)
        .margins(.vertical, 8)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
    override func setEditing(_ editing: Bool, animated: Bool) {}
}
