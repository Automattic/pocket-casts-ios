import Foundation
import Combine

/// Wraps the SwiftUI view in a `PlayerItemViewController` and adds some basic listeners
class BookmarksPlayerTabController: PlayerItemViewController {
    private let viewModel = BookmarkListViewModel(bookmarkManager: PlaybackManager.shared.bookmarkManager)

    private lazy var controller = {
        ThemedHostingController(rootView: BookmarksPlayerTab(viewModel: viewModel))
    }()

    private var cancellables = Set<AnyCancellable>()

    override func loadView() {
        self.view = controller.view.map {
            let view = UIStackView(arrangedSubviews: [$0])
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .clear
            return view
        } ?? UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(controller)
    }

    override func willBeAddedToPlayer() {
        updateCurrentEpisode()

        // Listen when the track changes and update the view model with the current episode
        Constants.Notifications.playbackTrackChanged.publisher().sink { [weak self] _ in
            self?.updateCurrentEpisode()
        }.store(in: &cancellables)
    }

    override func willBeRemovedFromPlayer() {
        viewModel.episode = nil
    }

    private func updateCurrentEpisode() {
        viewModel.episode = PlaybackManager.shared.currentEpisode()
    }
}
