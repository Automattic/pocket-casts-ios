import UIKit

class SecondaryLabel: ThemeableLabel {
    override init(frame: CGRect) {
        super.init(frame: frame)

        style = .primaryText02
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        style = .primaryText02
    }
}
