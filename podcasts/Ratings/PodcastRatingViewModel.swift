import SwiftUI
import PocketCastsServer

class PodcastRatingViewModel: ObservableObject {
    @Published var rating: PodcastRating? = nil

    /// Whether we should display the total ratings or not
    var showTotal: Bool = true

    private var state: LoadingState = .waiting

    /// Updates the rating for the podcast.
    ///
    func update(uuid: String) {
        // Don't update if we have already finished or are currently updating
        guard state == .waiting else { return }

        state = .loading

        Task {
            let rating = try? await RetrievePodcastRatingTask().retrieve(for: uuid)

            // Publish on main thread only
            await MainActor.run {
                self.rating = rating
            }

            state = .done
        }
    }

    private enum LoadingState {
        case waiting, loading, done
    }
}
