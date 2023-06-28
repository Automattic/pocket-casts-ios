import UIKit

class HeadphoneSettingsViewController: PCTableViewController {
    // MARK: - Data Struct

    private struct TableSection {
        /// The visible rows in the section
        var rows: [Row] {
            allRows.filter(\.visible)
        }

        /// Whether the section should be visible or not
        var visible: Bool {
            !rows.isEmpty
        }

        private let allRows: [Row]

        /// The footer text to display
        let footer: String

        init(rows: [Row], footer: String) {
            self.allRows = rows
            self.footer = footer
        }

        enum Row {
            case previousAction, nextAction
            case bookmarkSound

            var visible: Bool {
                switch self {
                case .bookmarkSound:
                    // Only show this option if the user has selected addBookmark as one of the options
                    let optionEnabled = [Settings.headphonesNextAction, Settings.headphonesPreviousAction].contains(.addBookmark)
                    // and the FeatureFlag is enabled
                    return FeatureFlag.bookmarks.enabled && optionEnabled
                default:
                    return true
                }
            }
        }
    }

}
