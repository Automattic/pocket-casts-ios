protocol ListHeaderDelegate: AnyObject {
    func searchTextChanged(searchText: String)
    func sortOrderChangeRequested()
}
