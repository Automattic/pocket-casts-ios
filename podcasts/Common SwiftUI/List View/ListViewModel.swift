import Foundation

/// A generic view model that represents a list of items
///
/// Usage:
///
///     class MyListViewModel: ListViewModel<MyCustomModel> {
///         ...
///     }
///
class ListViewModel<Model: Hashable>: ObservableObject {
    @Published var items: [Model] = [] {
        didSet {
            numberOfItems = items.count
        }
    }

    /// The total number of items, this value is automatically updated as the items array changes
    @Published private(set) var numberOfItems = 0

    // MARK: - Data

    func reload() { /* Subclasses should override this */ }

    // MARK: - Helpers

    /// Whether the given item is the last in the list
    func itemIsLast(_ item: Model) -> Bool {
        items.last == item
    }
}
