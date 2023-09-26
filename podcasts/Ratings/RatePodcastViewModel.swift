import SwiftUI
import PocketCastsDataModel

class RatePodcastViewModel: ObservableObject {
    @Binding var presented: Bool

    @Published var userCanRate: UserCanRate = .checking

    var podcast: Podcast

    init(presented: Binding<Bool>, podcast: Podcast) {
        self._presented = presented
        self.podcast = podcast
        checkIfUserCanRate()
    }

    func dismiss() {
        presented = false
    }

    private func checkIfUserCanRate() {
        // Check through an API if the user can rate this podcast
        userCanRate = .allowed
    }

    enum UserCanRate {
        case checking
        case allowed
        case disallowed
    }
}
