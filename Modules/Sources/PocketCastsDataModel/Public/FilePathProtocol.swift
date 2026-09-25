import Foundation

@objc public protocol FilePathProtocol {
    func tempPath(for episode: BaseEpisode) -> String
    func path(for episode: BaseEpisode) -> String
    func streamingBufferPath(for episode: BaseEpisode) -> String
}
