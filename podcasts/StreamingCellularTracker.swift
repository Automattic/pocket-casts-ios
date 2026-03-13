import AVFoundation
import Foundation
import Network
import PocketCastsDataModel
import PocketCastsUtils

/// Tracks network data usage for AVPlayer streaming by monitoring network path changes
/// and querying AVPlayerItem access logs for bytes transferred.
///
/// This is used for direct AVPlayer streaming (when not using MediaExporterResourceLoaderDelegate).
/// For cached streaming, network tracking is handled by MediaExporterResourceLoaderDelegate's
/// URLSessionTaskMetrics.
#if !os(watchOS)
class StreamingCellularTracker {
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.pocketcasts.StreamingCellularTracker")

    private weak var playerItem: AVPlayerItem?
    private var episodeUuid: String?
    private var podcastUuid: String?

    private var currentConnectionType: NetworkDataUsageManager.ConnectionType?
    private var bytesWhenConnectionStarted: Int64 = 0
    private var lastReportedBytes: Int64 = 0

    private var accessLogObserver: NSObjectProtocol?

    init() {}

    deinit {
        stopTracking()
    }

    /// Start tracking network usage for a player item
    func startTracking(playerItem: AVPlayerItem, episodeUuid: String?, podcastUuid: String?) {
        stopTracking()

        self.playerItem = playerItem
        self.episodeUuid = episodeUuid
        self.podcastUuid = podcastUuid
        self.lastReportedBytes = 0
        self.bytesWhenConnectionStarted = 0
        self.currentConnectionType = nil

        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
        monitor.start(queue: monitorQueue)

        // Observe access log changes to track bytes as they're downloaded
        accessLogObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewAccessLogEntry,
            object: playerItem,
            queue: nil
        ) { [weak self] _ in
            self?.checkAndReportConnectionUsage()
        }
    }

    /// Stop tracking and report final network usage
    func stopTracking() {
        reportCurrentConnectionUsageIfNeeded()

        monitor.cancel()

        if let observer = accessLogObserver {
            NotificationCenter.default.removeObserver(observer)
            accessLogObserver = nil
        }

        playerItem = nil
        episodeUuid = nil
        podcastUuid = nil
        currentConnectionType = nil
        bytesWhenConnectionStarted = 0
        lastReportedBytes = 0
    }

    // MARK: - Private

    private func handlePathUpdate(_ path: NWPath) {
        let previousConnectionType = currentConnectionType
        let nextConnectionType: NetworkDataUsageManager.ConnectionType? = {
            if path.usesInterfaceType(.cellular) {
                return .cellular
            }

            if path.usesInterfaceType(.wifi) {
                return .wifi
            }

            return nil
        }()

        guard previousConnectionType != nextConnectionType else {
            return
        }

        reportCurrentConnectionUsageIfNeeded()

        currentConnectionType = nextConnectionType
        bytesWhenConnectionStarted = currentBytesTransferred()
        lastReportedBytes = 0

        let connectionLabel = nextConnectionType?.displayName ?? "none"
        FileLog.shared.addMessage("StreamingCellularTracker: Switched connection type to \(connectionLabel), starting bytes: \(bytesWhenConnectionStarted)")
    }

    private func checkAndReportConnectionUsage() {
        guard currentConnectionType != nil else { return }

        let currentBytes = currentBytesTransferred()
        let bytesOnConnection = currentBytes - bytesWhenConnectionStarted

        let bytesThreshold: Int64 = 100 * 1024
        if bytesOnConnection - lastReportedBytes >= bytesThreshold {
            let bytesToReport = bytesOnConnection - lastReportedBytes
            reportConnectionBytes(bytesToReport)
            lastReportedBytes = bytesOnConnection
        }
    }

    private func reportCurrentConnectionUsageIfNeeded() {
        guard currentConnectionType != nil else { return }

        let currentBytes = currentBytesTransferred()
        let bytesOnConnection = currentBytes - bytesWhenConnectionStarted
        let unreportedBytes = bytesOnConnection - lastReportedBytes

        if unreportedBytes > 0 {
            reportConnectionBytes(unreportedBytes)
            lastReportedBytes = bytesOnConnection
        }
    }

    private func reportConnectionBytes(_ bytes: Int64) {
        guard bytes > 0, let connectionType = currentConnectionType else { return }

        FileLog.shared.addMessage("StreamingCellularTracker: Reporting \(bytes) bytes of \(connectionType.displayName) streaming for episode: \(episodeUuid ?? "unknown")")

        DataManager.sharedManager.networkDataUsageManager.add(
            episodeUuid: episodeUuid,
            podcastUuid: podcastUuid,
            bytesStreamed: bytes,
            operationType: .stream,
            connectionType: connectionType,
            sessionType: .foreground
        )
    }

    private func currentBytesTransferred() -> Int64 {
        guard let accessLog = playerItem?.accessLog(),
              let lastEvent = accessLog.events.last else {
            return 0
        }
        return lastEvent.numberOfBytesTransferred
    }
}

private extension NetworkDataUsageManager.ConnectionType {
    var displayName: String {
        switch self {
        case .unknown:
            return "unknown"
        case .wifi:
            return "wifi"
        case .cellular:
            return "cellular"
        }
    }
}
#endif
