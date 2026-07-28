import Foundation

@objc public protocol FilePathProtocol {
    func tempPathForEpisode(_ episode: BaseEpisode) -> String
    func pathForEpisode(_ episode: BaseEpisode) -> String
    func streamingBufferPathForEpisode(_ episode: BaseEpisode) -> String
}
