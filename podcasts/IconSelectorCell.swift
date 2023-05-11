import PocketCastsServer
import UIKit

protocol IconSelectorCellDelegate: AnyObject {
    func changeIcon(icon: IconType)
    func iconSelectorPresentingVC() -> UIViewController
}

enum IconType: Int, CaseIterable, AnalyticsDescribable {
    case primary, dark, roundLight, roundDark, indigo,
         rose, pocketCats, redVelvet, plus, classic, electricBlue,
         electricPink, radioactivity, halloween,
         patronChrome, patronRound, patronGlow, patronDark

    init(rawName: String) {
        self = IconType.allCases.first(where: { $0.iconName == rawName }) ?? IconType.primary
    }

    var description: String {
        switch self {
        case .primary:
            return L10n.appIconDefault
        case .dark:
            return L10n.appIconDark
        case .roundLight:
            return L10n.appIconRoundLight
        case .roundDark:
            return L10n.appIconRoundDark
        case .indigo:
            return L10n.appIconIndigo
        case .rose:
            return L10n.appIconRose
        case .pocketCats:
            return L10n.appIconPocketCats
        case .redVelvet:
            return L10n.appIconRedVelvet
        case .plus:
            return L10n.appIconPlus
        case .classic:
            return L10n.appIconClassic
        case .electricBlue:
            return L10n.appIconElectricBlue
        case .electricPink:
            return L10n.appIconElectricPink
        case .radioactivity:
            return L10n.appIconRadioactivity
        case .halloween:
            return L10n.appIconHalloween
        case .patronChrome:
            return L10n.appIconPatronChrome
        case .patronRound:
            return L10n.appIconPatronRound
        case .patronGlow:
            return L10n.appIconPatronGlow
        case .patronDark:
            return L10n.appIconPatronDark
        }
    }

    var icon: UIImage? {
        switch self {
        case .primary:
            return UIImage(named: "AppIcon-Default108x108")
        case .dark:
            return UIImage(named: "AppIcon-Dark108x108")
        case .roundLight:
            return UIImage(named: "AppIcon-Round-Light108x108")
        case .roundDark:
            return UIImage(named: "AppIcon-Round-Dark108x108")
        case .indigo:
            return UIImage(named: "AppIcon-Indigo108x108")
        case .rose:
            return UIImage(named: "AppIcon-Round-Pink108x108")
        case .pocketCats:
            return UIImage(named: "AppIcon-Pocket-Cats108x108")
        case .redVelvet:
            return UIImage(named: "AppIcon-Red-Velvet108x108")
        case .plus:
            return UIImage(named: "AppIcon-Plus108x108")
        case .classic:
            return UIImage(named: "AppIcon-Classic108x108")
        case .electricBlue:
            return UIImage(named: "AppIcon-Electric-Blue108x108")
        case .electricPink:
            return UIImage(named: "AppIcon-Electric-Pink108x108")
        case .radioactivity:
            return UIImage(named: "AppIcon-Radioactive108x108")
        case .halloween:
            return UIImage(named: "AppIcon-Halloween108x108")
        case .patronChrome:
            return UIImage(named: "AppIcon-Patron-Chrome")
        case .patronRound:
            return UIImage(named: "AppIcon-Patron-Round")
        case .patronGlow:
            return UIImage(named: "AppIcon-Patron-Glow")
        case .patronDark:
            return UIImage(named: "AppIcon-Patron-Dark")
        }
    }

    var iconName: String? {
        switch self {
        case .primary:
            return nil
        case .dark:
            return "AppIcon-Dark"
        case .roundLight:
            return "AppIcon-Round"
        case .roundDark:
            return "AppIcon-Round-Dark"
        case .indigo:
            return "AppIcon-Indigo"
        case .rose:
            return "AppIcon-Round-Pink"
        case .pocketCats:
            return "AppIcon-Pocket-Cats"
        case .redVelvet:
            return "AppIcon-Red-Velvet"
        case .plus:
            return "AppIcon-Plus"
        case .classic:
            return "AppIcon-Classic"
        case .electricBlue:
            return "AppIcon-Electric-Blue"
        case .electricPink:
            return "AppIcon-Electric-Pink"
        case .radioactivity:
            return "AppIcon-Radioactive"
        case .halloween:
            return "AppIcon-Halloween"
        case .patronChrome:
            return "AppIcon-Patron-Chrome"
        case .patronRound:
            return "AppIcon-Patron-Round"
        case .patronGlow:
            return "AppIcon-Patron-Glow"
        case .patronDark:
            return "AppIcon-Patron-Dark"
        }
    }

    var analyticsDescription: String {
        switch self {
        case .primary:
            return "default"
        case .dark:
            return "dark"
        case .roundLight:
            return "round_light"
        case .roundDark:
            return "round_dark"
        case .indigo:
            return "indigo"
        case .rose:
            return "rose"
        case .pocketCats:
            return "pocket_cats"
        case .redVelvet:
            return "red_velvet"
        case .plus:
            return "plus"
        case .classic:
            return "classic"
        case .electricBlue:
            return "electric_blue"
        case .electricPink:
            return "electric_pink"
        case .radioactivity:
            return "radioactive"
        case .halloween:
            return "halloween"
        case .patronChrome:
            return "patron_chrome"
        case .patronRound:
            return "patron_round"
        case .patronGlow:
            return "patron_glow"
        case .patronDark:
            return "patron_dark"
        }
    }
        }
    }
}

class IconSelectorCell: ThemeableCell, UICollectionViewDataSource, UICollectionViewDelegate, GridLayoutDelegate {
    @IBOutlet var collectionView: ThemeableAccessibilityCollectionView! {
        didSet {
            collectionView.register(UINib(nibName: "ThemeAbstractCell", bundle: nil), forCellWithReuseIdentifier: themeAbstractCellId)
            collectionView.style = .primaryUi02
            collectionView.allowsMultipleSelection = false
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if let gridLayout = collectionView.collectionViewLayout as? GridLayout {
            gridLayout.delegate = self
            gridLayout.numberOfRowsOrColumns = 1
            gridLayout.scrollDirection = .horizontal
            gridLayout.itemSpacing = itemSpacing
        }
    }

    private static let firstPaidIconIndex = 8

    private var numVisibleColoumns = 3 as CGFloat
    private var itemSpacing = 0 as CGFloat
    private var maxCellWidth = 124 as CGFloat
    var cellHeight: CGFloat {
        cellWidth * 148 / 124
    } // Design: width = 124 height = 148
    var peekWidth = 30 as CGFloat
    var cellWidth: CGFloat {
        let widthAvailable = UIScreen.main.bounds.width // view.bounds.width
        let maxWidth = maxCellWidth > 0 ? maxCellWidth : widthAvailable
        let calculatedWidth = min(maxWidth, (widthAvailable - peekWidth - (itemSpacing * (numVisibleColoumns + 1))) / numVisibleColoumns)
        return calculatedWidth
    }

    weak var delegate: IconSelectorCellDelegate!

    private let themeAbstractCellId = "ThemeAbstractCell"

    // MARK: - GridLayoutDelegate

    func sizeForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> CGSize {
        CGSize(width: cellWidth, height: cellHeight)
    }

    // MARK: - UICollectionView Methods

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        IconType.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: themeAbstractCellId, for: indexPath) as! ThemeAbstractCell

        cell.imageView.layer.cornerRadius = 18.95
        cell.shadowView.layer.cornerRadius = 18.95
        cell.underShadowView.layer.cornerRadius = 18.95
        cell.selectionView.layer.cornerRadius = 26

        let iconType = IconType(rawValue: indexPath.row) ?? .primary
        cell.nameLabel.text = iconType.description
        cell.imageView.image = iconType.icon

        cell.isLocked = !SubscriptionHelper.hasActiveSubscription() && indexPath.item > 7
        if UIApplication.shared.alternateIconName != nil {
            cell.isCellSelected = selectedIcon().rawValue == indexPath.item
        } else {
            cell.isCellSelected = indexPath.item == 0
        }

        cell.isAccessibilityElement = true
        cell.accessibilityLabel = cell.nameLabel.text
        if cell.isLocked {
            cell.accessibilityHint = L10n.accessibilityPlusOnly
        }
        return cell
    }

    // MARK: - CollectionView Delegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !SubscriptionHelper.hasActiveSubscription(), indexPath.item >= IconSelectorCell.firstPaidIconIndex {
            collectionView.deselectItem(at: indexPath, animated: true)

            NavigationManager.sharedManager.showUpsellView(from: delegate.iconSelectorPresentingVC(), source: .icons)
        } else {
            delegate?.changeIcon(icon: IconType(rawValue: indexPath.row) ?? .primary)
            collectionView.reloadData()
        }
    }

    func scrollToSelected() {
        let selectedItem = selectedIcon().rawValue
        collectionView.scrollToItem(at: IndexPath(item: selectedItem, section: 0), at: .centeredHorizontally, animated: false)
    }

    func setCurrentSelectedIcon() {
        let selectedItem = selectedIcon().rawValue
        collectionView.selectItem(at: IndexPath(item: selectedItem, section: 0), animated: true, scrollPosition: .centeredHorizontally)
    }

    func selectedIcon() -> IconType {
        let selectedIcon = UIApplication.shared.alternateIconName ?? ""
        return IconType(rawName: selectedIcon)
    }
}
