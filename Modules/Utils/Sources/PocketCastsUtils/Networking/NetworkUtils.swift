import Foundation

public class NetworkUtils {
    #if !os(watchOS)
        private lazy var reachability: Reachability = {
            let reachability = Reachability()!

            return reachability
        }()
    #endif

    private init() {}
    public static let shared = NetworkUtils()

    // MARK: - Connectivity

    public func isConnectedToWifi() -> Bool {
        #if os(watchOS)
            return true // TODO:
        #else
            return reachability.connection == .wifi
        #endif
    }
}
