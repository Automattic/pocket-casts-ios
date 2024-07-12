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

    var buttonOpacity: Double {
        if shouldHideButton {
            return 0
        }
        return isButtonEnabled ? 1 : 0.8
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
        if trackingEvent {
            let event: AnalyticsEvent = userCanRate == .allowed ? .ratingScreenDismissed : .notAllowedToRateScreenDismissed
            Analytics.shared.track(event)
        }
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
            let event: AnalyticsEvent = userCanRate == .allowed ? .ratingScreenShown : .notAllowedToRateScreenShown
            Analytics.shared.track(event, properties: ["uuid": uuid])
            self.userCanRate = userCanRate
        }
    }

    enum UserCanRate {
        case checking
        case allowed
        case disallowed
    }
}
