import Combine
import Foundation
import PocketCastsDataModel

class FiltersListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var filters: [Filter] = []
    private let playSourceViewModel = PlaySourceHelper.playSourceViewModel
    private var cancellables = Set<AnyCancellable>()

    init() {
        Publishers.Notification.dataUpdated
            .sink(receiveValue: { [unowned self] _ in
                self.loadData()
            })
            .store(in: &cancellables)
    }

    public func loadData() {
        isLoading = true
        playSourceViewModel.fetchFilters()
            .replaceError(with: [])
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] filters in
                self.isLoading = false
                self.filters = filters
            })
            .store(in: &cancellables)
    }

    func episodeCount(for filter: Filter) -> Int {
        return playSourceViewModel.episodeCount(for: filter)
    }
}
