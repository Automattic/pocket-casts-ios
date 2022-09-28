import UIKit

class EpisodeFilterChipCell: ThemeableCollectionCell {
    @IBOutlet var titleLabel: UILabel!

    var filterColor: UIColor? {
        didSet {
            updateColors()
        }
    }

    var isChipEnabled = false {
        didSet {
            updateColors()
        }
    }

    var backgroundIsPrimaryUI01 = false {
        didSet {
            updateColors()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = AppTheme.viewBackgroundColor()
        contentView.layer.borderWidth = 1
        contentView.layer.cornerRadius = 8
    }

    override func handleThemeDidChange() {
        updateColors()
    }

    private func updateColors() {
        guard let filterColor = filterColor else { return }

        if backgroundIsPrimaryUI01 {
            titleLabel.textColor = isChipEnabled ? ThemeColor.filterInteractive02(filterColor: filterColor) : ThemeColor.filterInteractive06(filterColor: filterColor)
            contentView.backgroundColor = isChipEnabled ? ThemeColor.filterInteractive01(filterColor: filterColor) : ThemeColor.primaryUi01()
            backgroundColor = isChipEnabled ? ThemeColor.primaryUi01() : contentView.backgroundColor

            let borderColor = isChipEnabled ? ThemeColor.filterInteractive01(filterColor: filterColor) : ThemeColor.filterInteractive06(filterColor: filterColor)
            contentView.layer.borderColor = borderColor.cgColor
        } else {
            titleLabel.textColor = isChipEnabled ? ThemeColor.filterInteractive04(filterColor: filterColor) : ThemeColor.filterInteractive05(filterColor: filterColor)
            contentView.backgroundColor = isChipEnabled ? ThemeColor.filterInteractive03(filterColor: filterColor) : ThemeColor.filterUi01(filterColor: filterColor)
            backgroundColor = isChipEnabled ? ThemeColor.filterUi01(filterColor: filterColor) : contentView.backgroundColor

            let borderColor = isChipEnabled ? ThemeColor.filterInteractive03(filterColor: filterColor) : ThemeColor.filterInteractive05(filterColor: filterColor)
            contentView.layer.borderColor = borderColor.cgColor
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        titleLabel.text = ""
    }
}
