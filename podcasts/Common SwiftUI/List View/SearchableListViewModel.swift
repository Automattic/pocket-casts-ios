import Combine
import PocketCastsUtils

///Allows a mode to be searched by the `SearchableListViewModel`
protocol SearchableDataModel: Hashable {
    /// Defines a field that the search text should match against
    /// This should contain all keywords for the model
    var searchableContent: String { get }
}

/// A generic list view model that allows the user to filter the items using the given `searchText`.
class SearchableListViewModel<Model: SearchableDataModel>: MultiSelectListViewModel<Model> {
    @Published var searchText: String = ""
    @Published private(set) var isSearching: Bool = false

    // The items that are filtered by the search text
    @Published private(set) var filteredItems: [Model] = [] {
        didSet {
            numberOfFilteredItems = filteredItems.count
        }
    }

    /// The number of items in the filtered array
    @Published private(set) var numberOfFilteredItems: Int = 0

    private var cancellables = Set<AnyCancellable>()

    /// If the items change update the filteredItems array
    override var items: [Model] {
        didSet {
            filterItemsIfNeeded()
        }
    }

    override init() {
        super.init()

        listenForSearchTextChanges()
    }

    // MARK: - Public

    /// Reset the search state
    func cancelSearch() {
        searchText = ""
        filteredItems = []
        isSearching = false
    }

    override func isLast(item: Model) -> Bool {
        guard isSearching else {
            return super.isLast(item: item)
        }

        return filteredItems.last == item
    }

    /// Searchs the items with the given text
    func search(with text: String) {
        let search = text.localizedLowercase.trim()

        guard !items.isEmpty, !search.isEmpty else {
            cancelSearch()
            return
        }

        isSearching = true

        // Filter the items by the search field
        filteredItems = items.filter { $0.searchField.localizedCaseInsensitiveContains(search) }
    }

    // Listen for debounced changes the the `searchText` property
    private func listenForSearchTextChanges() {
        $searchText
            .removeDuplicates()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] text in
                self?.search(with: text)
            })
            .store(in: &cancellables)
    }

    private func filterItemsIfNeeded() {
        guard isSearching else { return }

        search(with: searchText)
    }
}
