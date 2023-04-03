import PocketCastsServer

class PodcastRatingViewModel: ObservableObject {
    @Published var state: RatingState = .needsReload

    /// Updates the rating for the podcast.
    ///
    /// Changes are published on `self.state`.
    func update(uuid: String) {
        // Don't update if we have already finished or are currently updating
        guard case .needsReload = state else { return }

        state = .loading

        Task {
            let rating = try? await RetrievePodcastRatingTask().retrieve(for: uuid)

            // Publish on main thread only
            await MainActor.run {
                state = rating.map { .rating($0) } ?? .none
            }
        }
    }

    /// Represents the rating status for this podcast:
    ///
    /// - `needsReload`: The rating state is not known and needs to be reloaded from the server.
    /// - `loading`: The rating is being reloaded from the server
    /// - `none`: This podcast does not have a rating
    /// - `rating`: The podcast has a rating, and is provided as a `PodcastRating` value
    enum RatingState {
        case needsReload, loading, none, rating(PodcastRating)
    }
}
