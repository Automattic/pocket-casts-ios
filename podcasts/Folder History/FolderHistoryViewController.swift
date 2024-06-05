import Foundation

class FolderHistoryViewController: ThemedHostingController<FolderHistoryView> {
    convenience init() {
        self.init(rootView: FolderHistoryView())
    }
}
