import UIKit
import SwiftUI

class ReferralsClaimBannerTableCell: ThemeableCell {
    static var identifier = "ReferralsClaimBannerTableCellIdentifier"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let viewModel = ReferralClaimPassModel(offerInfo: ReferralsOfferInfoMock())

        let bannerView = ReferralsClaimBannerView(viewModel: viewModel).themedUIView
        bannerView.backgroundColor = .clear
        contentView.addSubview(bannerView)

        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalMargin),
            bannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalMargin),
            bannerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum Constants {
        static let horizontalMargin = CGFloat(16.0)
    }
}
