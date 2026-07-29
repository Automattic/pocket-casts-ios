import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp = Date()
    var relatedEpisodes: [RelatedEpisode]?

    enum Role {
        case user
        case assistant
    }
}

struct RelatedEpisode: Identifiable {
    let id = UUID()
    let title: String
    let podcastName: String
    let subtitle: String
}
