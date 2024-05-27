import Foundation

class UpNextHistoryViewController: ThemedHostingController<UpNextHistoryView> {
    convenience init() {
        self.init(rootView: UpNextHistoryView())
    }
}
