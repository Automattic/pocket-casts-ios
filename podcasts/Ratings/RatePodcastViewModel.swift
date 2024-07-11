import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

class RatePodcastViewModel: ObservableObject {
    @Binding var presented: Bool

    @Published var userCanRate: UserCanRate = .checking

    @Published var userPodcastRating: UserPodcastRating?

    @Published var isSubmitting: Bool = false

    @Published var showConfirmation: Bool = false

    @Published var anErrorOccurred: Bool = false

    @Published var stars: Double = 0 {
        didSet {
            if oldValue != stars {
                HapticsHelper.triggerStarHaptic()
            }
        }
    }

    let podcast: Podcast

    let dataManager: DataManager

    var buttonLabel: String {
        userCanRate == .allowed ? L10n.supportSubmit : L10n.done
    }

    var isButtonEnabled: Bool {
        userCanRate != .allowed || userCanRate == .allowed && stars > 0
    }

    var shouldHideButton: Bool {
        if let userPodcastRating {
            return Double(userPodcastRating.podcastRating) == stars
        }
        return false
    }

    init(presented: Binding<Bool>, podcast: Podcast, dataManager: DataManager = .sharedManager) {
        self._presented = presented
        self.podcast = podcast
        self.dataManager = dataManager
        checkIfUserCanRatePodcast(id: podcast.id, uuid: podcast.uuid)
    }

    func buttonAction() {
        userCanRate == .allowed ? submit() : dismiss()
    }

    func submit() {
        isSubmitting = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            let success = await ApiServerHandler.shared.addRating(uuid: self.podcast.uuid, rating: Int(self.stars))
            self.isSubmitting = false
            if success {
                self.dismiss()
                Toast.show(L10n.ratingThankYou)
            }
        }
    }

    func dismiss() {
        presented = false
    }

    private func checkIfUserCanRatePodcast(id: Int64, uuid: String) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let count = await self.dataManager.findPlayedEpisodesCount(podcastId: id)
            let userCanRate: UserCanRate = count < Constants.Values.numberOfEpisodesListenedRequiredToRate ? .disallowed : .allowed
            if userCanRate == .allowed,
               let userPodcastRating = await ApiServerHandler.shared.getRating(uuid: uuid) {
                self.stars = Double(userPodcastRating.podcastRating)
                self.userPodcastRating = userPodcastRating
            }
            self.userCanRate = userCanRate
        }
    }

    enum UserCanRate {
        case checking
        case allowed
        case disallowed
    }
}
