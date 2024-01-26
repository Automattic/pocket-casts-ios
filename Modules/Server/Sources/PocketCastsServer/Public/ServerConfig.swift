import Foundation

public class ServerConfig {
    public static let shared = ServerConfig()

    public static var avoidLogoutOnError = false

    private var backgroundSessionHandler: (() -> Void)?

    // MARK: - App values required for Server communication

    public var syncDelegate: ServerSyncDelegate?
    public var playbackDelegate: ServerPlaybackDelegate?

    public func setBackgroundSessionCompletionHandler(handler: (() -> Void)?) {
        backgroundSessionHandler = handler
    }

    public func backgroundSessionCompletionHandler() -> (() -> Void)? {
        backgroundSessionHandler
    }
}
