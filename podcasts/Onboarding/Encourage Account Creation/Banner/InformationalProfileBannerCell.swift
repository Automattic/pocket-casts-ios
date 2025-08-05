import UIKit

class InformationalProfileBannerCell: ThemeableCell {
    static var identifier = "InformationalBannerIdentifier"

    lazy private var informationalBannerCoordinator: InformationalBannerViewCoordinator = {
        let viewModel = InformationalBannerViewModel(bannerType: .profile)
        return InformationalBannerViewCoordinator(viewModel: viewModel)
    }()

    var onCloseBannerTap: ((InformationalProfileBannerCell?) -> Void)? = nil

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        informationalBannerCoordinator.onDismissBanner = { [weak self] in
            self?.onCloseBannerTap?(self)
        }

        guard let bannerView = informationalBannerCoordinator.bannerView() else {
            return
        }
        contentView.addSubview(bannerView)
        bannerView.anchorToAllSidesOf(view: contentView)

        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
