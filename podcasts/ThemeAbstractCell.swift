import UIKit

class ThemeAbstractCell: UICollectionViewCell {
    @IBOutlet var nameLabel: ThemeableLabel! {
        didSet {
            nameLabel.setLetterSpacing(-0.02)
            nameLabel.sizeToFit()
        }
    }

    @IBOutlet var selectionView: ThemeableSelectionView! {
        didSet {
            selectionView.layer.borderWidth = 4
            selectionView.unselectedStyle = .primaryUi02
        }
    }

    @IBOutlet var imageView: UIImageView! {
        didSet {
            imageView.clipsToBounds = true
        }
    }

    @IBOutlet var shadowView: ThemeableView! {
        didSet {
            shadowView.clipsToBounds = false
            shadowView.layer.shadowColor = AppTheme.appearanceShadowColor().cgColor
            shadowView.layer.shadowOpacity = 1
            shadowView.layer.shadowRadius = 5
            shadowView.layer.cornerRadius = 10
            shadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
        }
    }

    @IBOutlet var underShadowView: ThemeableView! {
        didSet {
            underShadowView.layer.cornerRadius = 10
            underShadowView.style = .contrast04
            underShadowView.alpha = 0.5
        }
    }

    @IBOutlet var cornerImage: UIImageView! {
        didSet {
            setCornerImage()
        }
    }

    var isLocked: Bool = true {
        didSet {
            imageView.alpha = isLocked ? 0.5 : 1
            nameLabel.style = isLocked ? .primaryText02 : .primaryText01
            setCornerImage()
        }
    }

    var lockImage: UIImage? = nil {
        didSet {
            setCornerImage()
        }
    }

    private func setCornerImage() {
        if isCellSelected {
            cornerImage.image = UIImage(named: "tickBlueCircle")
        } else {
            cornerImage.image = isLocked ? lockImage : nil
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.clipsToBounds = false
        clipsToBounds = false
    }

    var isCellSelected = false {
        didSet {
            selectionView.isSelected = isCellSelected
            setCornerImage()
        }
    }

    override func prepareForReuse() {
        isCellSelected = false
    }
}
