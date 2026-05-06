import SwiftUI

@Observable
class WelcomeViewModel {
    var podcasts: [MockPodcast] = MockData.makePodcasts()
}
