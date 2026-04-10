import Foundation
import PocketCastsDataModel

public class ServerConfig {
    public static let shared = ServerConfig()

    private var backgroundSessionHandler: (() -> Void)?

    // MARK: - App values required for Server communication

    public var syncDelegate: ServerSyncDelegate?
    public var playbackDelegate: ServerPlaybackDelegate?

    /// Error logger for reporting sync errors to crash reporting services (e.g., Sentry)
    public var errorLogger: ErrorLogger?

    public func setBackgroundSessionCompletionHandler(handler: (() -> Void)?) {
        backgroundSessionHandler = handler
    }

    public func backgroundSessionCompletionHandler() -> (() -> Void)? {
        backgroundSessionHandler
    }
}
