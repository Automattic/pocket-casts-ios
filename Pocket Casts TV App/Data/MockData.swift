import Foundation

struct MockPodcast: Identifiable {
    var id: String
    var name: String
    var image: String
}

struct MockData {

    static func makePodcasts() -> [MockPodcast] {
        let numberOfPodcasts = 48
        var results = [MockPodcast]()
        for i in (0..<numberOfPodcasts) {
            results.append(MockPodcast(id: UUID().uuidString, name: "Podcast \(i+1)", image: "Covers/login-cover-\( (i % 10) + 1)"))
        }
        return results
    }
}
