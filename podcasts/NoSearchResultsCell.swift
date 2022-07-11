import UIKit

class NoSearchResultsCell: ThemeableCell {
    @IBOutlet var detailLabel: ThemeableLabel! {
        didSet {
            detailLabel.style = .primaryText02
        }
    }
}
