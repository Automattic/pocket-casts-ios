import Foundation

extension UITableView {
    func selectIndexPath(_ indexPath: IndexPath) {
        selectRow(at: indexPath, animated: false, scrollPosition: .none)
        delegate?.tableView?(self, didSelectRowAt: indexPath)
    }

    func deselectIndexPath(_ indexPath: IndexPath) {
        deselectRow(at: indexPath, animated: false)
        delegate?.tableView?(self, didDeselectRowAt: indexPath)
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

    func deselectAllAbove(indexPath: IndexPath) {
        let targetIndexPath = IndexPath(row: max(0, indexPath.row - 1), section: indexPath.section)
        deselectAllFrom(fromIndexPath: IndexPath(row: 0, section: 0), toIndexPath: targetIndexPath)
    }

    func deselectAllBelow(indexPath: IndexPath) {
        guard numberOfSections > 0 else { return }
        let lastSection = numberOfSections - 1
        let lastRow = numberOfRows(inSection: lastSection) - 1
        let targetIndexPath = IndexPath(row: min(lastRow, indexPath.row + 1), section: indexPath.section)
        deselectAllFrom(fromIndexPath: targetIndexPath, toIndexPath: IndexPath(row: lastRow, section: lastSection))
    }

    func deselectAllFrom(fromIndexPath: IndexPath, toIndexPath: IndexPath) {
        for section in fromIndexPath.section ... toIndexPath.section {
            let startingRow = fromIndexPath.section == section ? fromIndexPath.row : 0
            let endingRow = toIndexPath.section == section ? toIndexPath.row : numberOfRows(inSection: section) - 1
            for row in startingRow ... endingRow {
                let thisPath = IndexPath(row: row, section: section)
                deselectIndexPath(thisPath)
            }
        }
    }

    func allAboveAreSelected(indexPath: IndexPath) -> Bool {
        areSelected(fromIndexPath: IndexPath(row: 0, section: indexPath.section), toIndexPath: indexPath)
    }

    func allBelowAreSelected(indexPath: IndexPath) -> Bool {
        guard numberOfSections > 0 else { return false }
        let lastSection = numberOfSections - 1
        return areSelected(fromIndexPath: indexPath, toIndexPath: IndexPath(row: numberOfRows(inSection: lastSection) - 1, section: lastSection))
    }

    func areSelected(fromIndexPath: IndexPath, toIndexPath: IndexPath) -> Bool {
        for section in fromIndexPath.section ... toIndexPath.section {
            let startingRow = fromIndexPath.section == section ? fromIndexPath.row : 0
            let endingRow = toIndexPath.section == section ? toIndexPath.row : numberOfRows(inSection: section) - 1
            for row in startingRow ... endingRow {
                let thisPath = IndexPath(row: row, section: section)
                if indexPathsForSelectedRows?.contains(thisPath) != true {
                    return false
                }
            }
        }
        return true
    }
}
