import UIKit
import SwiftUI

class ReferralsClaimBannerTableCell: ThemeableCell {
    static var identifier = "ReferralsClaimBannerTableCellIdentifier"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let viewModel = ReferralClaimPassModel(offerDuration: "2 Months")

        let bannerView = ReferralsClaimBannerView(viewModel: viewModel).themedUIView
        bannerView.backgroundColor = .clear
        contentView.addSubview(bannerView)

        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            bannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0),
            bannerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
