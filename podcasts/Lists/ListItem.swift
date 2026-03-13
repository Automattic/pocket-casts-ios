import DifferenceKit
import Foundation

class ListItem: Differentiable, Equatable {
    var differenceIdentifier: String {
        ""
    }

    func isContentEqual(to source: ListItem) -> Bool {
        handleIsEqual(source)
    }

    static func == (lhs: ListItem, rhs: ListItem) -> Bool {
        lhs.handleIsEqual(rhs)
    }

    // Due to some super funky type erasure nonsense, subclasses should override this for when the parent gets called instead
    func handleIsEqual(_ otherItem: ListItem) -> Bool {
        true
    }
}
