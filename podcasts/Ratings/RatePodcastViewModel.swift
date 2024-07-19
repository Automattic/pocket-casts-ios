import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

class RatePodcastViewModel: ObservableObject {
    @Binding var presented: Bool

    @Binding var dismissAction: DismissAction

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

    var buttonOpacity: Double {
        if shouldHideButton {
            return 0
        }
        return isButtonEnabled ? 1 : 0.8
    }

    init(presented: Binding<Bool>, dismissAction: Binding<DismissAction>, podcast: Podcast, dataManager: DataManager = .sharedManager) {
        self._presented = presented
        self._dismissAction = dismissAction
        self.podcast = podcast
        self.dataManager = dataManager
        checkIfUserCanRatePodcast(id: podcast.id, uuid: podcast.uuid)
    }

    func buttonAction() {
        userCanRate == .allowed ? submit() : dismiss()
    }

    func submit() {
        isSubmitting = true
        Analytics.shared.track(.ratingScreenSubmitTapped,
                               properties: ["uuid": podcast.uuid,
                                            "stars": stars])
        Task { @MainActor [weak self] in
            guard let self else { return }
            let success = await ApiServerHandler.shared.addRating(uuid: self.podcast.uuid, rating: Int(self.stars))
            self.isSubmitting = false
            if success {
                self.dismiss(trackingEvent: false)
                Toast.show(L10n.ratingThankYou)
            }
        }
    }

    func dismiss(trackingEvent: Bool = true) {
        if !trackingEvent {
            dismissAction = .default
        }
        presented = false
    }

    private func checkIfUserCanRatePodcast(id: Int64, uuid: String) {
        Task { [weak self] in
            guard let self else { return }
            // Some podcasts can have just one episode.
            // Let's use the episode count to compute the requirement to rate
            let episodeCount = self.dataManager.findEpisodeCount(podcastId: id)

            // This shouldn't be necessary, but just in case it's empty we return
            guard episodeCount > 0 else { return }
            let playedEpisodesCount = await self.dataManager.findPlayedEpisodesCount(podcastId: id)

            // If the episode count is 1 -> requirement to rate is 1
            // If the episode count is > 1 -> requirement to rate is 2
            let requirementToRate = min(episodeCount, Constants.Values.numberOfEpisodesListenedRequiredToRate)
            let userCanRate: UserCanRate = playedEpisodesCount < requirementToRate ? .disallowed : .allowed
            if userCanRate == .allowed,
               let userPodcastRating = await ApiServerHandler.shared.getRating(uuid: uuid) {
                await MainActor.run {
                    self.stars = Double(userPodcastRating.podcastRating)
                    self.userPodcastRating = userPodcastRating
                }
            }
            let event: AnalyticsEvent = userCanRate == .allowed ? .ratingScreenShown : .notAllowedToRateScreenShown
            Analytics.shared.track(event, properties: ["uuid": uuid])
            await MainActor.run {
                self.userCanRate = userCanRate
                self.setDismissAction()
            }
        }
    }

    private func setDismissAction() {
        let dismissEvent: AnalyticsEvent = userCanRate == .allowed ? .ratingScreenDismissed : .notAllowedToRateScreenDismissed
        dismissAction = .dismissAndTracking(dismissEvent)
    }

    enum UserCanRate {
        case checking
        case allowed
        case disallowed
    }

    enum DismissAction {
        case dismissAndTracking(AnalyticsEvent)
        case `default`
    }
}
