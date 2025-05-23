import UIKit
import SwiftUI

class KidsProfileBannerTableCell: ThemeableCell {
    static var identifier = "KidsProfileBannerTableCellIdentifier"

    var onCloseButtonTap: ((KidsProfileBannerTableCell?) -> Void)? = nil
    var onRequestEarlyAccessTap: ((KidsProfileBannerTableCell?) -> Void)? = nil

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let viewModel = KidsProfileBannerViewModel()
        viewModel.onCloseButtonTap = { [weak self] in
            self?.onCloseButtonTap?(self)
        }

        viewModel.onRequestEarlyAccessTap = { [weak self] in
            self?.onRequestEarlyAccessTap?(self)
        }

        let kidsProfileBannerView = KidsProfileBannerView(viewModel: viewModel).themedUIView
        kidsProfileBannerView.backgroundColor = .clear
        contentView.addSubview(kidsProfileBannerView)

        kidsProfileBannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            kidsProfileBannerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            kidsProfileBannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0),
            kidsProfileBannerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16.0),
            kidsProfileBannerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
