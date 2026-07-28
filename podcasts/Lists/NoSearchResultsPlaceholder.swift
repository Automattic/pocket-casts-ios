import Foundation

class NoSearchResultsPlaceholder: ListItem {
    override var differenceIdentifier: String {
        "noSaarchResults"
    }

    static func == (lhs: NoSearchResultsPlaceholder, rhs: NoSearchResultsPlaceholder) -> Bool {
        lhs.handleIsEqual(rhs)
    }

    override func handleIsEqual(_ otherItem: ListItem) -> Bool {
        otherItem is NoSearchResultsPlaceholder
    }
}
