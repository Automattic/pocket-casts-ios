import Foundation

extension UITableView {
    func selectIndexPath(_ indexPath: IndexPath) {
        selectRow(at: indexPath, animated: false, scrollPosition: .none)
        delegate?.tableView?(self, didSelectRowAt: indexPath)
    }

    func selectAll() {
        guard numberOfSections > 0 else { return }
        let lastSection = numberOfSections - 1

        selectAllFrom(fromIndexPath: IndexPath(row: 0, section: 0), toIndexPath: IndexPath(row: numberOfRows(inSection: lastSection) - 1, section: lastSection))
    }

    func deselectAll() {
        indexPathsForSelectedRows?.forEach {
            deselectRow(at: $0, animated: true)
            delegate?.tableView?(self, didDeselectRowAt: $0)
        }
    }

    func selectAllAbove(indexPath: IndexPath) {
        selectAllFrom(fromIndexPath: IndexPath(row: 0, section: 0), toIndexPath: indexPath)
    }

    func selectAllBelow(indexPath: IndexPath) {
        guard numberOfSections > 0 else { return }
        let lastSection = numberOfSections - 1
        selectAllFrom(fromIndexPath: indexPath, toIndexPath: IndexPath(row: numberOfRows(inSection: lastSection) - 1, section: lastSection))
    }

    func selectAllFrom(fromIndexPath: IndexPath, toIndexPath: IndexPath) {
        for section in fromIndexPath.section ... toIndexPath.section {
            let startingRow = fromIndexPath.section == section ? fromIndexPath.row : 0
            let endingRow = toIndexPath.section == section ? toIndexPath.row : numberOfRows(inSection: section) - 1
            for row in startingRow ... endingRow {
                let thisPath = IndexPath(row: row, section: section)
                selectIndexPath(thisPath)
            }
        }
    }
}
