import UIKit

protocol TitleButtonDelegate: AnyObject {
    func arrowTapped()
}

class TitleViewWithCollapseButton: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var arrowButton: ExpandCollapseButton!

    weak var delegate: TitleButtonDelegate?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadViewFromNib()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewFromNib()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func loadViewFromNib() {
        Bundle.main.loadNibNamed("TitleViewWithCollapseButton", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }

    @IBAction func buttonTapped(_ sender: Any) {
        delegate?.arrowTapped()
    }

    func setTintColor(newColor: UIColor) {
        arrowButton.tintColor = newColor
        titleLabel.textColor = newColor
    }
}
