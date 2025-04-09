import UIKit

class InformationalProfileBannerCell: ThemeableCell {
    static var identifier = "InformationalBannerIdentifier"

    let viewModel = InformationalBannerViewModel(bannerType: .profile)

    var onCloseBannerTap: ((InformationalProfileBannerCell?) -> Void)? = nil
    var onCreateFreeAccountTap: ((InformationalProfileBannerCell?) -> Void)? = nil

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        viewModel.onCloseBannerTap = { [weak self] in
            self?.onCloseBannerTap?(self)
        }

        viewModel.onCreateFreeAccountTap = { [weak self] in
            self?.onCreateFreeAccountTap?(self)
        }

        let bannerView = InformationalBannerView(viewModel: viewModel).themedUIView
        contentView.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
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
