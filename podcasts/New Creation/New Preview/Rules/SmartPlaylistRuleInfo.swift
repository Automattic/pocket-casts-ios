import Foundation

struct SmartPlaylistRuleInfo: Identifiable {
    let id = UUID()
    let type: SmartPlaylistRule
    let description: String?

    init(type: SmartPlaylistRule, description: String? = nil) {
        self.type = type
        self.description = description
    }
}
