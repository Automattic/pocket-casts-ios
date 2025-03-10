import Foundation
import Network

public class NetworkUtils {

    private var monitor: NWPathMonitor = {
        let monitor = NWPathMonitor()

        return monitor
    }()

    private init() {
        monitor.start(queue: .main)
    }

    deinit {
        monitor.cancel()
    }

    public static let shared = NetworkUtils()

    // MARK: - Connectivity

    public func isConnectedToUnexpensiveConnection() -> Bool {
        return !monitor.currentPath.isExpensive
    }

    public func isConnected() -> Bool {
        monitor.currentPath.status == .satisfied
    }
}
