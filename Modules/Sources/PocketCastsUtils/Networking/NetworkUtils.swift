import Foundation
import Network

public class NetworkUtils {

    private lazy var monitor = NWPathMonitor()
    private var connectionHandlers: [UUID: () -> Void] = [:]

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            switch path.status {
            case .satisfied:
                FileLog.shared.addMessage("NetworkMonitor: Network is connected isExpensive: \(path.isExpensive)")
                self?.performConnectionHandlers()
            case .unsatisfied:
                FileLog.shared.addMessage("NetworkMonitor: Network is disconnected")
            case .requiresConnection:
                FileLog.shared.addMessage("NetworkMonitor: Network requires connection")
            @unknown default:
                FileLog.shared.addMessage("NetworkMonitor: Unknown path status")
            }
        }
        monitor.start(queue: .main)
    }

    deinit {
        monitor.cancel()
    }

    public static let shared = NetworkUtils()

    // MARK: - Connectivity

    public func isConnectedToUnexpensiveConnection() -> Bool {
        if FeatureFlag.useCellularNetworkApis.enabled {
            return !monitor.currentPath.usesInterfaceType(.cellular)
        } else {
            return !monitor.currentPath.isExpensive
        }
    }

    public func isConnected() -> Bool {
        monitor.currentPath.status == .satisfied
    }

    /// Calls `handler` on the main queue as soon as the network is connected, or after `timeout` if it isn't connected by then.
    public func whenConnected(timeout: TimeInterval, perform handler: @escaping () -> Void) {
        DispatchQueue.main.async { [self] in
            if isConnected() {
                handler()
                return
            }

            let id = UUID()
            connectionHandlers[id] = handler
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.connectionHandlers.removeValue(forKey: id)?()
            }
        }
    }

    private func performConnectionHandlers() {
        let handlers = connectionHandlers.values
        connectionHandlers.removeAll()
        handlers.forEach { $0() }
    }
}
