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
        selectedIDs.formUnion(idsBefore(item))
    }

    func selectAllAfter(_ item: Model) {
        selectedIDs.formUnion(idsAfter(item))
    }

    func deselectAllBefore(_ item: Model) {
        selectedIDs.subtract(idsBefore(item))
    }

    func deselectAllAfter(_ item: Model) {
        selectedIDs.subtract(idsAfter(item))
    }

    func hasSelectedAllBefore(_ item: Model) -> Bool {
        areSelected(idsBefore(item))
    }

    func hasSelectedAllAfter(_ item: Model) -> Bool {
        areSelected(idsAfter(item))
    }

    /// The items up to and including the given one
    private func idsBefore(_ item: Model) -> [Model.ID] {
        guard let index = index(of: item) else { return [] }

        return selectableItems[...index].map(\.id)
    }

    /// The given item and everything after it
    private func idsAfter(_ item: Model) -> [Model.ID] {
        guard let index = index(of: item) else { return [] }

        return selectableItems[index...].map(\.id)
    }

    private func areSelected(_ ids: [Model.ID]) -> Bool {
        !ids.isEmpty && selectedIDs.isSuperset(of: ids)
    }

    private func index(of item: Model) -> Int? {
        selectableItems.firstIndex { $0.id == item.id }
    }

    // MARK: - Long Press

    /// A long press enters the multi selection and picks the item, or offers the Select/Deselect
    /// All Above/Below options when it's already active
    func longPressed(_ item: Model) {
        guard isMultiSelecting else {
            isMultiSelecting = true
            select(item.id)
            return
        }

        showSelectAllOptions(for: item)
    }

    /// Offers the same Select/Deselect All Above/Below options as the table view based lists: each
    /// direction flips to its Deselect variant once everything that way is selected, and is left
    /// out entirely for an item at that end of the list
    private func showSelectAllOptions(for item: Model) {
        guard let index = index(of: item) else { return }

        var actions = [OptionAction]()

        if index > 0 {
            let allAboveAreSelected = hasSelectedAllBefore(item)

            actions.append(.init(
                label: allAboveAreSelected ? L10n.deselectAllAbove : L10n.selectAllAbove,
                icon: allAboveAreSelected ? "deselectall-up" : "selectall-up"
            ) { [weak self] in
                if allAboveAreSelected {
                    self?.deselectAllBefore(item)
                } else {
                    self?.selectAllBefore(item)
                }
            })
        }

        if index < selectableItems.count - 1 {
            let allBelowAreSelected = hasSelectedAllAfter(item)

            actions.append(.init(
                label: allBelowAreSelected ? L10n.deselectAllBelow : L10n.selectAllBelow,
                icon: allBelowAreSelected ? "deselectall-down" : "selectall-down"
            ) { [weak self] in
                if allBelowAreSelected {
                    self?.deselectAllAfter(item)
                } else {
                    self?.selectAllAfter(item)
                }
            })
        }

        guard !actions.isEmpty else { return }

        let optionPicker = OptionsPicker(title: nil, iconTintStyle: .primaryIcon02)
        optionPicker.addActions(actions)
        optionPicker.present()
    }
}
