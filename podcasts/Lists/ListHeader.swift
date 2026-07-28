import Foundation

class ListHeader: ListItem {
    let headerTitle: String
    let isSectionHeader: Bool
    let sectionNumber: Int

    init(headerTitle: String, isSectionHeader: Bool, sectionNumber: Int) {
        self.headerTitle = headerTitle
        self.isSectionHeader = isSectionHeader
        self.sectionNumber = sectionNumber
        super.init()
    }

    override var differenceIdentifier: String {
        headerTitle
    }

    static func == (lhs: ListHeader, rhs: ListHeader) -> Bool {
        lhs.handleIsEqual(rhs)
    }

    override func handleIsEqual(_ otherItem: ListItem) -> Bool {
        guard let rhs = otherItem as? ListHeader else { return false }

        return headerTitle == rhs.headerTitle && isSectionHeader == rhs.isSectionHeader
    }
}
