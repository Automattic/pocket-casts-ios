import SwiftUI

class LoadingCell: UITableViewCell {
    static let reuseIdentifier = "LoadingCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
