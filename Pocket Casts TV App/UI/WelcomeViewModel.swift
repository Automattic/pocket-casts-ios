import SwiftUI

@Observable
class WelcomeViewModel {
    var images: [String] = {
        var results = [String]()
        for i in (0..<48) {
            let podcastImageName = "Covers/login-cover-\( (i % 10) + 1)"
            results.append(podcastImageName)
        }
        return results
    }()
}
