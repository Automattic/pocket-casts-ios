import Foundation
import Combine

/// Wraps the SwiftUI view in a `PlayerItemViewController` and adds some basic listeners
class BookmarksPlayerTabController: PlayerItemViewController {
    private let viewModel: BookmarkListViewModel
    let controller: ThemedHostingController<BookmarksPlayerTab>

    private var cancellables = Set<AnyCancellable>()

    init(bookmarkManager: BookmarkManager) {
        let viewModel = BookmarkListViewModel(bookmarkManager: bookmarkManager)
        self.viewModel = viewModel
        self.controller = ThemedHostingController(rootView: BookmarksPlayerTab(viewModel: viewModel))

        super.init(nibName: nil, bundle: nil)
    }

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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
