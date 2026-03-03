import Foundation

class AllArchivedPlaceholder: ListItem {
    let archived: Int
    let message: String

    init(archived: Int, message: String) {
        self.archived = archived
        self.message = message

        super.init()
    }

    override var differenceIdentifier: String {
        "allArchived"
    }

    static func == (lhs: AllArchivedPlaceholder, rhs: AllArchivedPlaceholder) -> Bool {
        lhs.handleIsEqual(rhs)
    }

    override func handleIsEqual(_ otherItem: ListItem) -> Bool {
        guard let rhs = otherItem as? AllArchivedPlaceholder else { return false }

        return archived == rhs.archived
    }
}
