import SwiftUI

class LoadingCell: UITableViewCell {
    static let reuseIdentifier = "LoadingCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        if #available(iOS 16.0, *) {
            self.contentConfiguration = UIHostingConfiguration {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(Color(uiColor: ThemeColor.primaryIcon01()))
                    Text(L10n.loading)
                        .font(style: .subheadline)
                        .foregroundStyle(Color(uiColor: ThemeColor.primaryText02()))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
            .margins(.horizontal, 16)
        } else {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 16
            stackView.alignment = .center
            stackView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(stackView)

            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.color = ThemeColor.primaryIcon01()
            activityIndicator.startAnimating()

            let label = UILabel()
            label.text = L10n.loading
            label.font = .systemFont(ofSize: 15)
            label.textColor = ThemeColor.primaryText02()

            stackView.addArrangedSubview(activityIndicator)
            stackView.addArrangedSubview(label)

            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                stackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
                stackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
                contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
            ])
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
