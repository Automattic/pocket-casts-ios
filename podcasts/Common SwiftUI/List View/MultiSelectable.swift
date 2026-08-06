import Foundation

/// A list view model whose items the user can select several of at once.
///
/// Conform and publish the two pieces of state; the selection itself comes with it:
///
///     class MyListViewModel: ListViewModel<MyCustomModel>, MultiSelectable {
///         @Published var isMultiSelecting = false
///         @Published var selectedIDs: Set<MyCustomModel.ID> = []
///
///         var selectableItems: [MyCustomModel] { items }
///
///         override var items: [MyCustomModel] {
///             didSet { selectableItemsDidChange() }
///         }
///     }
///
/// It's a protocol rather than a base class so a view model picks up the multi selection alongside
/// whatever else it already is, instead of every list in the same hierarchy inheriting it.
///
/// Only the ids are kept, so the list stays the single source of truth: items that leave it drop
/// out of the selection on their own.
@MainActor
protocol MultiSelectable: AnyObject {
    associatedtype Model: Identifiable

    /// The list the selection is made from, which a conformer showing a filtered list can narrow.
    /// Call `selectableItemsDidChange()` whenever it changes.
    var selectableItems: [Model] { get }

    var isMultiSelecting: Bool { get set }

    var selectedIDs: Set<Model.ID> { get set }
}

extension MultiSelectable {
    // MARK: - Reading the Selection

    /// The currently selected items, in the order they appear in the list
    var selectedItems: [Model] {
        selectableItems.filter { selectedIDs.contains($0.id) }
    }

    var hasSelectedAll: Bool {
        !selectableItems.isEmpty && selectableItems.allSatisfy { selectedIDs.contains($0.id) }
    }

    func isSelected(_ item: Model) -> Bool {
        selectedIDs.contains(item.id)
    }

    // MARK: - Entering / Exiting Multi Select

    func toggleMultiSelection() {
        deselectAll()
        isMultiSelecting.toggle()
    }

    /// Call whenever `selectableItems` changes: emptying the list also leaves the multi selection,
    /// as there's nothing left to select
    func selectableItemsDidChange() {
        guard isMultiSelecting, selectableItems.isEmpty else { return }

        toggleMultiSelection()
    }

    // MARK: - Item Selection

    private func select(_ id: Model.ID) {
        selectedIDs.insert(id)
    }

    private func deselect(_ id: Model.ID) {
        selectedIDs.remove(id)
    }

    func toggleSelected(_ item: Model) {
        isSelected(item) ? deselect(item.id) : select(item.id)
    }

    // MARK: - Select All / Deselect All

    func toggleSelectAll() {
        hasSelectedAll ? deselectAll() : selectAll()
    }

    private func selectAll() {
        selectedIDs = Set(selectableItems.map(\.id))
    }

    private func deselectAll() {
        selectedIDs.removeAll()
    }

    // MARK: - Select All Before/After

    func selectAllBefore(_ item: Model) {
        guard let index = index(of: item) else { return }

        selectedIDs.formUnion(selectableItems[...index].map(\.id))
    }

    func selectAllAfter(_ item: Model) {
        guard let index = index(of: item) else { return }

        selectedIDs.formUnion(selectableItems[index...].map(\.id))
    }

    private func index(of item: Model) -> Int? {
        selectableItems.firstIndex { $0.id == item.id }
    }

    // MARK: - Long Press

    /// A long press enters the multi selection and picks the item, or offers the Select All
    /// Above/Below options when it's already active
    func longPressed(_ item: Model) {
        guard isMultiSelecting else {
            isMultiSelecting = true
            select(item.id)
            return
        }

        showSelectAllOptions(for: item)
    }

    /// Offers the Select All Above/Below options for the long pressed item
    private func showSelectAllOptions(for item: Model) {
        let optionPicker = OptionsPicker(title: nil)

        optionPicker.addActions([
            .init(label: L10n.selectAllAbove, icon: "selectall-up") { [weak self] in
                self?.selectAllBefore(item)
            },
            .init(label: L10n.selectAllBelow, icon: "selectall-down") { [weak self] in
                self?.selectAllAfter(item)
            }
        ])

        optionPicker.present()
    }
}
