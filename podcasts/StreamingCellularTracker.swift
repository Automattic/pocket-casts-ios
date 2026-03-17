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
///
/// DB writes happen only on connection type changes and when tracking stops (not during streaming).
/// An access log observer keeps an in-memory byte count up to date so that flushes are accurate.
#if !os(watchOS)
class StreamingCellularTracker {
    private var monitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.pocketcasts.StreamingCellularTracker")

    private weak var playerItem: AVPlayerItem?
    private var episodeUuid: String?
    private var podcastUuid: String?

    private var currentConnectionType: NetworkDataUsageManager.ConnectionType = .unknown
    private var bytesWhenConnectionStarted: Int64 = 0
    private var lastReportedBytes: Int64 = 0
    private var latestBytesTransferred: Int64 = 0

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
        self.currentConnectionType = .unknown
        self.latestBytesTransferred = 0

        let newMonitor = NWPathMonitor()
        newMonitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
        newMonitor.start(queue: monitorQueue)
        monitor = newMonitor

        // Observe access log changes to keep our in-memory byte count current.
        // No DB writes happen here — we only flush on connection change or stop.
        accessLogObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewAccessLogEntry,
            object: playerItem,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            self.monitorQueue.async {
                self.updateBytesTransferred()
            }
        }
    }

    /// Stop tracking and report final network usage
    func stopTracking() {
        monitorQueue.sync {
            updateBytesTransferred()
            reportCurrentConnectionUsageIfNeeded()
        }

        monitor?.cancel()
        monitor = nil

        if let observer = accessLogObserver {
            NotificationCenter.default.removeObserver(observer)
            accessLogObserver = nil
        }

        playerItem = nil
        episodeUuid = nil
        podcastUuid = nil
        currentConnectionType = .unknown
        bytesWhenConnectionStarted = 0
        lastReportedBytes = 0
        latestBytesTransferred = 0
    }

    // MARK: - Private

    private func handlePathUpdate(_ path: NWPath) {
        let previousConnectionType = currentConnectionType
        let nextConnectionType: NetworkDataUsageManager.ConnectionType = {
            if path.usesInterfaceType(.cellular) {
                return .cellular
            }

            if path.usesInterfaceType(.wifi) {
                return .wifi
            }

            return .unknown
        }()

        guard previousConnectionType != nextConnectionType else {
            return
        }

        updateBytesTransferred()
        reportCurrentConnectionUsageIfNeeded()

        currentConnectionType = nextConnectionType
        bytesWhenConnectionStarted = latestBytesTransferred
        lastReportedBytes = 0

        let connectionLabel = nextConnectionType.displayName
        FileLog.shared.addMessage("StreamingCellularTracker: Switched connection type to \(connectionLabel), starting bytes: \(bytesWhenConnectionStarted)")
    }

    /// Updates the cached byte count from the access log (no DB write).
    private func updateBytesTransferred() {
        guard let accessLog = playerItem?.accessLog() else {
            return
        }
        latestBytesTransferred = accessLog.events.reduce(0) { $0 + $1.numberOfBytesTransferred }
    }

    private func reportCurrentConnectionUsageIfNeeded() {
        let bytesOnConnection = latestBytesTransferred - bytesWhenConnectionStarted
        let unreportedBytes = bytesOnConnection - lastReportedBytes

        if unreportedBytes > 0 {
            reportConnectionBytes(unreportedBytes)
            lastReportedBytes = bytesOnConnection
        }
    }

    private func reportConnectionBytes(_ bytes: Int64) {
        guard bytes > 0 else { return }
        let connectionType = currentConnectionType

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
