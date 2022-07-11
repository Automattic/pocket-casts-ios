import UIKit

class AllArchivedCell: ThemeableCell {
    @IBOutlet var episodesArchivedLabel: ThemeableLabel! {
        didSet {
            episodesArchivedLabel.style = .primaryText02
        }
    }
}
