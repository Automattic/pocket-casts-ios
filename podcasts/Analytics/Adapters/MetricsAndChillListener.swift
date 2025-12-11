#if DEBUG
import Foundation
import PocketCastsServer
import PocketCastsUtils

/// Local websocket forwarder for analytics events.
final class MetricsAndChillListener: NSObject, AnalyticsAdapter {
    private enum Config {
        static let urlString = "ws://localhost:8080/input?token=admin:brandon.titus@automattic.com"
        static let maxPendingEvents = 2_000
        static let reconnectStep: TimeInterval = 15
        static let reconnectMax: TimeInterval = 60
    }

    private struct InputEvent: Codable {
        let name: String
        let timestamp: Date
        let properties: [String: String?]?
        let platform: String
    }

    private lazy var session: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let stateQueue = DispatchQueue(label: "au.com.shiftyjelly.pocketcasts.metricsandchill")

    private var pendingEvents: [InputEvent] = []
    private var shouldBeConnected = false
    private var webSocketTask: URLSessionWebSocketTask?
    private var reconnectWorkItem: DispatchWorkItem?
    private var reconnectAttempt: Int = 0
    private var loginObserver: NSObjectProtocol?

    override init() {
        super.init()
        observeLoginChanges()
        stateQueue.async { [weak self] in
            self?.updateConnectionState(isLoggedIn: SyncManager.isUserLoggedIn())
        }
    }

    deinit {
        if let loginObserver {
            NotificationCenter.default.removeObserver(loginObserver)
        }
        stateQueue.sync {
            teardownSocket()
        }
    }

    func track(name: String, properties: [AnyHashable: Any]?) {
        stateQueue.async { [weak self] in
            guard let self else { return }

            let event = InputEvent(
                name: name,
                timestamp: Date(),
                properties: properties?.reduce(into: [String: String?]()) { partialResult, entry in
                    partialResult[String(describing: entry.key)] = String(describing: entry.value)
                },
                platform: "iOS"
            )

            if self.webSocketTask != nil {
                self.send(events: [event])
            } else {
                self.enqueue(event: event)
            }
        }
    }
}

// MARK: - Connection Management

private extension MetricsAndChillListener {
    func observeLoginChanges() {
        loginObserver = NotificationCenter.default.addObserver(forName: .userLoginDidChange, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            stateQueue.async {
                self.updateConnectionState(isLoggedIn: SyncManager.isUserLoggedIn())
            }
        }
    }

    func updateConnectionState(isLoggedIn: Bool) {
        shouldBeConnected = isLoggedIn

        if isLoggedIn {
            openWebSocketIfNeeded()
        } else {
            teardownSocket()
        }
    }

    func openWebSocketIfNeeded() {
        guard shouldBeConnected, webSocketTask == nil, let url = URL(string: Config.urlString) else {
            return
        }

        reconnectAttempt = 0
        let task = session.webSocketTask(with: url)
        task.resume()
        webSocketTask = task
    }

    func teardownSocket() {
        cancelReconnect()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }

    func scheduleReconnect() {
        guard shouldBeConnected, reconnectWorkItem == nil else {
            return
        }

        let delay = min(TimeInterval(reconnectAttempt) * Config.reconnectStep, Config.reconnectMax)
        reconnectAttempt += 1

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.reconnectWorkItem = nil
            self.openWebSocketIfNeeded()

            if self.webSocketTask == nil {
                self.scheduleReconnect()
            }
        }

        reconnectWorkItem = workItem
        stateQueue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    func cancelReconnect() {
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        reconnectAttempt = 0
    }
}

// MARK: - Event Handling

private extension MetricsAndChillListener {
    private func enqueue(event: InputEvent) {
        if pendingEvents.count >= Config.maxPendingEvents {
            pendingEvents.removeFirst(pendingEvents.count - Config.maxPendingEvents + 1)
        }
        pendingEvents.append(event)
    }

    func flushPendingEvents() {
        guard !pendingEvents.isEmpty else { return }
        let events = pendingEvents
        pendingEvents.removeAll()
        send(events: events)
    }

    private func send(events: [InputEvent]) {
        guard let webSocketTask else {
            events.forEach { enqueue(event: $0) }
            return
        }

        guard let data = try? encoder.encode(events), let json = String(data: data, encoding: .utf8) else {
            return
        }

        webSocketTask.send(.string(json)) { [weak self] error in
            guard let self, let error else { return }
            stateQueue.async {
                events.forEach { self.enqueue(event: $0) }
                self.webSocketTask = nil
                self.scheduleReconnect()
                FileLog.shared.addMessage("MetricsAndChill send error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension MetricsAndChillListener: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        stateQueue.async { [weak self] in
            guard let self, self.webSocketTask === webSocketTask else { return }
            cancelReconnect()
            flushPendingEvents()
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        stateQueue.async { [weak self] in
            guard let self, self.webSocketTask === webSocketTask else { return }
            self.webSocketTask = nil
            self.scheduleReconnect()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error, let webSocketTask = task as? URLSessionWebSocketTask else { return }

        stateQueue.async { [weak self] in
            guard let self, self.webSocketTask === webSocketTask else { return }
            self.webSocketTask = nil
            self.scheduleReconnect()
            FileLog.shared.addMessage("MetricsAndChill socket failure: \(error.localizedDescription)")
        }
    }
}
#endif
