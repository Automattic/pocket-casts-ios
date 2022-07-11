import UIKit

class SwitchCell: ThemeableCell {
    @IBOutlet var cellSwitch: ThemeableSwitch!
    @IBOutlet var cellLabel: UILabel!
    @IBOutlet var cellSecondaryLabel: ThemeableLabel! {
        didSet {
            cellSecondaryLabel.style = .primaryText02
        }
    }
    
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var cellTextToImageConstraint: NSLayoutConstraint!
    
    var switchStyle: ThemeStyle = .primaryInteractive01
    
    var isLocked = true {
        didSet {
            cellSwitch.isUserInteractionEnabled = isLocked
            contentView.alpha = isLocked ? 1 : 0.3
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setNoImage()
    }
    
    override func handleThemeDidChange() {
        let color = AppTheme.colorForStyle(switchStyle)
        cellSwitch.onTintColor = color
        cellImage.tintColor = color
    }
    
    func setImage(imageName: String) {
        cellTextToImageConstraint.isActive = true
        cellImage.tintColor = cellSwitch.onTintColor
        cellImage.image = UIImage(named: imageName)
    }
    
    func setNoImage() {
        cellTextToImageConstraint.isActive = false
        cellImage.image = nil
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
}
