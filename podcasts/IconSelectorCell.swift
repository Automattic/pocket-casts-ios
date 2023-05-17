import PocketCastsServer
import UIKit

protocol IconSelectorCellDelegate: AnyObject {
    func changeIcon(icon: IconType)
    func iconSelectorPresentingVC() -> UIViewController
}

enum IconType: Int, CaseIterable, AnalyticsDescribable {
    case primary, dark, roundLight, roundDark, indigo
    case rose, pocketCats, redVelvet, plus, classic, electricBlue
    case electricPink, radioactivity, halloween
    case patronChrome, patronRound, patronGlow, patronDark

    /// Finds the IconType for the given iconName or .primary if there isn't a match
    init(iconName: String) {
        self = Self.availableIcons.first(where: { $0.iconName == iconName }) ?? .primary
    }

    static var availableIcons: [IconType] {
        Self.allCases.filter {
            $0.subscription <= (FeatureFlag.patron.enabled ? .patron : .plus)
        }
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

    var previewIconName: String {
        switch self {
        case .primary:
            return "AppIcon-Default"
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

    /// Whether the icon is unlocked for the users active subscription
    var isUnlocked: Bool {
        SubscriptionHelper.activeSubscriptionTier >= subscription
    }

    /// The minimum subscription level required to unlock the icon
    var subscription: SubscriptionTier {
        switch self {
        case .patronChrome, .patronRound, .patronGlow, .patronDark:
            return .patron
        case .plus, .classic, .electricBlue, .electricPink, .radioactivity, .halloween:
            return .plus
        default:
            return .none
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

        selectedIcon = IconType(iconName: UIApplication.shared.alternateIconName ?? "")

        if let gridLayout = collectionView.collectionViewLayout as? GridLayout {
            gridLayout.delegate = self
            gridLayout.numberOfRowsOrColumns = 1
            gridLayout.scrollDirection = .horizontal
            gridLayout.itemSpacing = itemSpacing
        }
    }

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

    weak var delegate: IconSelectorCellDelegate?

    private let themeAbstractCellId = "ThemeAbstractCell"

    var selectedIcon: IconType = .primary

    // MARK: - GridLayoutDelegate

    func sizeForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> CGSize {
        CGSize(width: cellWidth, height: cellHeight)
    }

    // MARK: - UICollectionView Methods

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        IconType.availableIcons.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: themeAbstractCellId, for: indexPath) as! ThemeAbstractCell

        cell.imageView.layer.cornerRadius = 18.95
        cell.shadowView.layer.cornerRadius = 18.95
        cell.underShadowView.layer.cornerRadius = 18.95
        cell.selectionView.layer.cornerRadius = 26

        let iconType = IconType(rawValue: indexPath.row) ?? .primary
        cell.nameLabel.text = iconType.description
        cell.imageView.image = UIImage(named: iconType.previewIconName)
        cell.isLocked = !iconType.isUnlocked

        cell.isCellSelected = selectedIcon == iconType

        cell.isAccessibilityElement = true
        cell.accessibilityLabel = cell.nameLabel.text

        if cell.isLocked {
            switch iconType.subscription {
            case .patron:
                cell.accessibilityHint = L10n.accessibilityPatronOnly
                cell.lockImage = UIImage(named: "patron-locked")
            default:
                cell.accessibilityHint = L10n.accessibilityPlusOnly
                cell.lockImage = UIImage(named: "plusGoldCircle")
            }
        }

        return cell
    }

    // MARK: - CollectionView Delegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let icon = IconType(rawValue: indexPath.item), icon.isUnlocked else {
            collectionView.deselectItem(at: indexPath, animated: true)

            if let delegate {
                let context: OnboardingFlow.Context? = IconType(rawValue: indexPath.item).flatMap {
                    ["product": Constants.ProductInfo(plan: $0.subscription == .patron ? .patron : .plus, frequency: .yearly)]
                }

                NavigationManager.sharedManager.showUpsellView(from: delegate.iconSelectorPresentingVC(), source: .icons, context: context)
            }
            return
        }

        selectedIcon = icon
        delegate?.changeIcon(icon: icon)
        collectionView.reloadData()
    }

    func scrollToSelected() {
        collectionView.scrollToItem(at: IndexPath(item: selectedIcon.rawValue, section: 0), at: .centeredHorizontally, animated: false)
    }
}
