import Foundation

public struct SiriPodcastItem: Codable {
    public var name: String
    public var uuid: String

    public init(name: String, uuid: String) {
        self.name = name
        self.uuid = uuid
    }
}
