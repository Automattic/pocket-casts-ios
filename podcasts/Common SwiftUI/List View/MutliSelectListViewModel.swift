import Foundation

/// A generic list view model that allows the user to enter a mode that allows them to select multiple items from the list and perform actions on those items
///
/// Usage:
///
///     class MyListViewModel: MutliSelectListViewModel<MyCustomModel> {
///         ...
///     }
class MutliSelectListViewModel<Model: Hashable>: ListViewModel<Model> {
    /// Whether the list is currently in the multi selection mode
    @Published private(set) var isMultiSelecting = false

    /// The total number of items that are currently selected
    @Published private(set) var numberOfSelectedItems = 0

    /// Whether all the items in the list have been selected
    @Published private(set) var hasSelectedAll = false

    /// An internal set that keeps track of the items that are currently selected
    private lazy var selectedItems: Set<Model> = [] {
        didSet {
            updateCounts()
        }
    }

    // MARK: - Entering / Exiting Multi Select
    func toggleMultiSelection() {
        deselectAll()
        isMultiSelecting.toggle()
    }

    // MARK: - Item Selection

    func isSelected(_ item: Model) -> Bool {
        selectedItems.contains(where: { $0 == item })
    }

    func select(item: Model) {
        selectedItems.insert(item)
    }

    func deselect(item: Model) {
        selectedItems.remove(item)
    }

    func toggleSelected(_ item: Model) {
        isSelected(item) ? deselect(item: item) : select(item: item)
    }

    // MARK: - Select All / Deselect All

    func toggleSelectAll() {
        hasSelectedAll ? deselectAll() : selectAll()
    }

    func selectAll() {
        selectedItems = Set(items)
    }

    func deselectAll() {
        selectedItems.removeAll()
    }

    // MARK: - Select All Before/After

    func selectAllBefore(_ item: Model) {
        guard let index = items.firstIndex(of: item) else { return }

        selectedItems.formUnion(items[...index])
    }

    func selectAllAfter(_ item: Model) {
        guard let index = items.firstIndex(of: item) else { return }

        selectedItems.formUnion(items[index...])
    }

    // MARK: - Long Press

    /// Handles when an item is long pressed:
    /// - If we're not currently in the multi selection mode, then we'll enter and select the pressed item
    /// - Otherwise we'll show the Select All Above/Below options picker
    func longPressed(_ item: Model) {
        // If we're not multiselecting, then enter and select the long pressed item
        guard isMultiSelecting else {
            isMultiSelecting = true
            select(item: item)
            return
        }

        // Show the select all above/below options
        showOptionsPicker(item)
    }
}

// MARK: - Private Methods

private extension MutliSelectListViewModel {
    func updateCounts() {
        let selected = selectedItems.count
        numberOfSelectedItems = selected
        hasSelectedAll = selected == items.count
    }

    /// Shows the option picker to allow for Select All Above/Below
    func showOptionsPicker(_ item: Model) {
        let optionPicker = OptionsPicker(title: nil)

        optionPicker.addActions([
            .init(label: L10n.selectAllAbove, icon: "selectall-up") { [weak self] in
                self?.selectAllBefore(item)
            },
            .init(label: L10n.selectAllBelow, icon: "selectall-down") { [weak self] in
                self?.selectAllAfter(item)
            }
        ])

        optionPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }
}
