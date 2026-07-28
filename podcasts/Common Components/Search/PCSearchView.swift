import SwiftUI

struct PCSearchView: UIViewControllerRepresentable {
    @Binding var searchTerm: String

    let shouldShowCancelButton: Bool

    static let defaultIndenting: CGFloat = 16
    static let defaultHeight = PCSearchBarController.defaultHeight

    init(searchTerm: Binding<String>, shouldShowCancelButton: Bool = false) {
        self._searchTerm = searchTerm
        self.shouldShowCancelButton = shouldShowCancelButton
    }

    class Coordinator: NSObject, PCSearchBarDelegate {
        var parent: PCSearchView

        init(_ parent: PCSearchView) {
            self.parent = parent
        }

        func searchDidBegin() {}
        func searchDidEnd() {
            parent.searchTerm = ""
        }

        func searchWasCleared() {
            parent.searchTerm = ""
        }

        func searchTermChanged(_ searchTerm: String) {
            parent.searchTerm = searchTerm
        }

        func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
            parent.searchTerm = searchTerm
            completion()
        }
    }

    func makeUIViewController(context: Context) -> PCSearchBarController {
        let searchController = PCSearchBarController()
        searchController.shouldShowCancelButton = shouldShowCancelButton
        searchController.searchDelegate = context.coordinator
        searchController.backgroundColorOverride = UIColor.clear
        searchController.placeholderText = L10n.searchPodcasts

        return searchController
    }

    func updateUIViewController(_ uiViewController: PCSearchBarController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
