import Foundation
import UIKit

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

    func selectAllAbove(fromIndexPath: IndexPath, to indexPath: IndexPath) {
        selectAllFrom(fromIndexPath: fromIndexPath, toIndexPath: indexPath)
    }

    func selectAllBelow(fromIndexPath: IndexPath) {
        guard numberOfSections > 0 else { return }
        let lastSection = numberOfSections - 1
        selectAllFrom(fromIndexPath: fromIndexPath, toIndexPath: IndexPath(row: numberOfRows(inSection: lastSection) - 1, section: lastSection))
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

    func deselectAllAbove(fromIndexPath: IndexPath, to indexPath: IndexPath) {
        deselectAllFrom(fromIndexPath: fromIndexPath, toIndexPath: indexPath)
    }

    func deselectAllBelow(indexPath: IndexPath) {
        guard numberOfSections > 0 else { return }
        let lastSection = numberOfSections - 1
        let lastRow = numberOfRows(inSection: lastSection) - 1
        deselectAllFrom(fromIndexPath: indexPath, toIndexPath: IndexPath(row: lastRow, section: lastSection))
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

    func allAboveAreSelected(fromIndexPath: IndexPath, to indexPath: IndexPath) -> Bool {
        areSelected(fromIndexPath: fromIndexPath, toIndexPath: indexPath)
    }

    func allBelowAreSelected(indexPath: IndexPath) -> Bool {
        guard numberOfSections > 0 else { return false }
        let lastSection = numberOfSections - 1
        return areSelected(fromIndexPath: indexPath, toIndexPath: IndexPath(row: numberOfRows(inSection: lastSection) - 1, section: lastSection))
    }

    func areSelected(
        fromIndexPath: IndexPath,
        toIndexPath: IndexPath
    ) -> Bool {
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

    // Returns the first index path in the table, excluding any cells matching the provided types
    func firstIndexPath(
        section: Int,
        excludingCellTypes: [UITableViewCell.Type]? = nil
    ) -> IndexPath? {
        guard numberOfSections > 0 else { return nil }
        return firstIndexPath(from: IndexPath(row: 0, section: section), excludingCellTypes: excludingCellTypes)
    }

    // Returns the first index path starting from a given index path (inclusive),
    // excluding any cells matching the provided types
    func firstIndexPath(
        from startIndexPath: IndexPath,
        excludingCellTypes: [UITableViewCell.Type]?
    ) -> IndexPath? {
        guard numberOfSections > 0 else { return nil }

        let lastSection = numberOfSections - 1
        var section = startIndexPath.section
        while section <= lastSection {
            let rows = numberOfRows(inSection: section)
            if rows > 0 {
                let startRow = (section == startIndexPath.section) ? startIndexPath.row : 0
                var row = startRow
                while row < rows {
                    let path = IndexPath(row: row, section: section)
                    if let types = excludingCellTypes, !types.isEmpty,
                       let cell = self.cellForRow(at: path),
                       types.contains(where: { cell.isKind(of: $0) }) {
                        // skip excluded types
                    } else {
                        return path
                    }
                    row += 1
                }
            }
            section += 1
        }
        return nil
    }
}
