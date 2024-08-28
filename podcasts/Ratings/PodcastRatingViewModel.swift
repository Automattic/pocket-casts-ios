import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

class PodcastRatingViewModel: ObservableObject {
    @Published var rating: PodcastRating? = nil
    @Published var presentingGiveRatings = false

    var presentLogin: ((PodcastRatingViewModel) -> Void)? = nil

    /// Whether we should display the total ratings or not
    var showTotal: Bool = true

    var hasRatings: Bool {
        guard let rating else {
            return false
        }
        return rating.total > 0
    }

    private var state: LoadingState = .waiting

    /// Internally track the podcast UUID
    /// We don't init with this because the podcast view controller may not have
    /// the uuid yet
    private(set) var uuid: String? = nil

    private(set) var podcast: Podcast?

    /// Updates the rating for the podcast.
    ///
    func update(podcast: Podcast?, ignoringCache: Bool = false) {
        // If we want to reload and ignore the cache, let's reset the state to waiting and reload
        if ignoringCache, state == .done {
            state = .waiting
        }

        self.podcast = podcast

        // Don't update if we have already finished or are currently updating
        guard state == .waiting, let uuid = podcast?.uuid else { return }

        self.uuid = uuid
        state = .loading

        Task {
            let rating = try? await PodcastRatingTask().retrieve(for: uuid, ignoringCache: ignoringCache)

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

    enum RatingSource: String {
        case button
        case stars
    }
}

// MARK: - View Interactions
extension PodcastRatingViewModel {
    func didTapRating(source: RatingSource = .button) {
        if FeatureFlag.giveRatings.enabled {
            Analytics.shared.track(.ratingStarsTapped,
                                   properties: ["uuid": uuid ?? "unknown",
                                                "source": source.rawValue])
            if SyncManager.isUserLoggedIn() {
                presentingGiveRatings = true
            } else {
                DispatchQueue.main.async {
                    self.presentLogin?(self)
                }
            }
        } else {
            presentingGiveRatings = true

            Analytics.shared.track(.ratingStarsTapped, properties: ["uuid": uuid ?? "unknown"])
        }
    }
}
