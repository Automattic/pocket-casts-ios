import SwiftUI

class RatePodcastViewModel: ObservableObject {
    @Binding var presented: Bool

    @Published var userCanRate: UserCanRate = .checking

    var podcastUuid: String

    init(presented: Binding<Bool>, podcastUuid: String) {
        self._presented = presented
        self.podcastUuid = podcastUuid
        checkIfUserCanRate()
    }

    private func checkIfUserCanRate() {
        // Check through an API if the user can rate this podcast
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.userCanRate = .disallowed
        }
    }

    enum UserCanRate {
        case checking
        case allowed
        case disallowed
    }
}
