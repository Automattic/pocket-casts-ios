import Foundation
import AVFoundation
import UIKit
import PocketCastsServer
import PocketCastsUtils

#if !os(watchOS)
/// MediaExporterItemConfiguration global configuration.
private enum MediaExporterItemConfiguration {
    /// How much data is downloaded in memory before stored on a file.
    public static var downloadBufferLimit: Int {
        FeatureFlag.streamAndDownloadReadFromMemoryBuffer.enabled ? 256.KB : 16.KB
    }

    /// How much data is allowed to be read in memory at a time.
    public static var readDataLimit: Int = 5.MB

    /// Flag for deciding whether an error should be thrown when URLResponse's expectedContentLength is not equal with the downloaded media file bytes count. Defaults to `false`.
    public static var shouldVerifyDownloadedFileSize: Bool = false

    /// If set greater than 0, the set value with be compared with the downloaded media size. If the size of the downloaded media is lower, an error will be thrown. Useful when `expectedContentLength` is unavailable.
    /// Default value is `0`.
    public static var minimumExpectedFileSize: Int = 0
}

fileprivate extension Int {
    var KB: Int { return self * 1024 }
    var MB: Int { return self * 1024 * 1024 }
}

/// Responsible for downloading media data and providing the requested data parts.
class MediaExporterResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    private let lock = NSLock()

    var bufferData = Data()
    private let downloadBufferLimit = MediaExporterItemConfiguration.downloadBufferLimit
    private let readDataLimit = MediaExporterItemConfiguration.readDataLimit

    private var fileHandle: MediaFileHandle

    private var session: URLSession?
    var response: URLResponse?
    private let queue = DispatchQueue(label: "com.pocketcasts.MediaExporterResourceLoaderDelegate", qos: .userInitiated, attributes: .concurrent)
    private var pendingRequests: Set<AVAssetResourceLoadingRequest> {
        get { queue.sync { return pendingRequestsValue } }
        set { queue.async(flags: .barrier) { [weak self] in self?.pendingRequestsValue = newValue } }
    }
    private var pendingRequestsValue = Set<AVAssetResourceLoadingRequest>()
    private var isDownloadComplete = false
    var deleteFileOnRelease = false
    var hasRetriedWithoutUserAgent = false

    private let saveFilePath: String
    private let callback: FileExporterProgressReport?
    private lazy var callbackQueue: DispatchQueue = {
        let queue: DispatchQueue
        if FeatureFlag.useBackgroundQueueForStreamingCallback.enabled {
            queue = DispatchQueue(label: "com.pocketcasts.MediaExporterResourceLoaderDelegate.callback", qos: .default, attributes: [])
        } else {
            queue = DispatchQueue.main
        }
        return queue
    }()

    enum FileExportStatus {
        case downloading
        case completed
        case failed(Error)
    }

    typealias FileExporterProgressReport = (_ status: FileExportStatus, _ contentType: String?, _ downloaded: Int64, _ total: Int64) -> ()

    // MARK: Init
    init(saveFilePath: String, callback: FileExporterProgressReport?) {
        self.saveFilePath = saveFilePath
        self.callback = callback
        self.fileHandle = MediaFileHandle(filePath: saveFilePath)
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }

    deinit {
        FileLog.shared.addMessage("MediaExporterResourceLoaderDelegate: Releasing loader for \(saveFilePath)")
        session?.invalidateAndCancel()
        session = nil
        if deleteFileOnRelease {
            fileHandle.deleteFile()
        }
    }

    static let schemePrefix = "custom-"

    static func makeCustomURL(_ original: URL) -> URL? {
        return URL(string: "\(Self.schemePrefix)\(original.absoluteString)")
    }

    static func resolveOriginalURL(from url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.scheme = components.scheme?.replacingOccurrences(of: Self.schemePrefix, with: "")
        return components.url
    }

    // MARK: AVAssetResourceLoaderDelegate

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url,
              let originalURL = Self.resolveOriginalURL(from: url)
        else {
            return false
        }

        if session == nil {
            // If we're playing from an url, we need to download the file.
            // We start loading the file on first request only.
            startDataRequest(with: originalURL)
        }

        pendingRequests.insert(loadingRequest)
        processPendingRequests()
        return true
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        pendingRequests.remove(loadingRequest)
    }

    // MARK: URLSessionDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        bufferData.append(data)
        writeBufferDataToFileIfNeeded()
        processPendingRequests()
        let contentType = response?.mimeType
        callbackQueue.async { [weak self] in
            guard let self else { return }
            self.callback?(.downloading, contentType, Int64(self.fileHandle.fileSize), dataTask.countOfBytesExpectedToReceive)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response
        processPendingRequests()
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            downloadFailed(with: error)
            return
        }

        if !bufferData.isEmpty {
            do {
                try fileHandle.append(data: bufferData)
            } catch {
                downloadFailed(with: error)
                return
            }
        }

        let error = verifyResponse()

        guard error == nil else {
            if shouldRetryWithoutUserAgent(error: error!) {
                retryWithoutUserAgent(originalURL: task.originalRequest?.url)
                return
            }

            downloadFailed(with: error!)
            return
        }

        downloadComplete()
    }

    // MARK: Internal methods

    func startDataRequest(with url: URL) {
        startDataRequest(with: url, retryWithoutUserAgent: false)
    }

    @objc func startDataRequest(with url: URL, retryWithoutUserAgent: Bool) {
        FileLog.shared.addMessage("MediaExporterResourceLoaderDelegate: Start data request for \(url)")
        guard session == nil else { return }

        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if FeatureFlag.streamingCustomSessionConfiguration.enabled {
            configuration.networkServiceType = .avStreaming
            configuration.allowsCellularAccess = true
            configuration.timeoutIntervalForRequest = 60 // seconds
            configuration.timeoutIntervalForResource = 3600 * 2 // seconds
#if !APPCLIP
            configuration.waitsForConnectivity = false
            configuration.multipathServiceType = .handover // allows switching between celular/wifi
#endif
        }

        var urlRequest = URLRequest(url: url)
        if !retryWithoutUserAgent {
            urlRequest.setValue(ServerConstants.Values.appUserAgent, forHTTPHeaderField: ServerConstants.HttpHeaders.userAgent)
        }

        if retryWithoutUserAgent {
            hasRetriedWithoutUserAgent = true
            FileLog.shared.addMessage("MediaExporterResourceLoaderDelegate: Starting request without User-Agent header")
        }

        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        if let task = session?.dataTask(with: urlRequest) {
            task.priority = URLSessionTask.highPriority
            task.resume()
        }
    }

    func invalidateAndCancelSession(shouldResetData: Bool = true, error: Error? = nil) {
        session?.invalidateAndCancel()
        session = nil

        if shouldResetData {
            bufferData = Data()
            pendingRequests.forEach { request in
                request.finishLoading(with: error)
            }
            pendingRequests.removeAll()
        }

        // We need to only remove the file if it hasn't been fully downloaded
        guard isDownloadComplete == false else { return }

        fileHandle.deleteFile()
    }

    // MARK: Private methods

    private func processPendingRequests() {
        lock.lock()
        defer { lock.unlock() }

        // Filter out the unfullfilled requests
        let requestsFulfilled: Set<AVAssetResourceLoadingRequest> = pendingRequests.filter {
            fillInContentInformationRequest($0.contentInformationRequest)
            guard haveEnoughDataToFulfillRequest($0.dataRequest!) else { return false }

            $0.finishLoading()
            return true
        }

        // Remove fulfilled requests from pending requests
        requestsFulfilled.forEach { pendingRequests.remove($0) }
    }

    private func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
        // Do we have response from the server?
        guard let response = response else { return }

        contentInformationRequest?.contentType = response.mimeType
        contentInformationRequest?.contentLength = response.expectedContentLength
        contentInformationRequest?.isByteRangeAccessSupported = true
    }

    private func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        let requestedOffset = Int(dataRequest.requestedOffset)
        let requestedLength = dataRequest.requestedLength
        let currentOffset = Int(dataRequest.currentOffset)
        let bytesCached = fileHandle.fileSize

        // Is there enough data cached to fulfill the request?
        guard bytesCached > currentOffset else {
            if FeatureFlag.streamAndDownloadReadFromMemoryBuffer.enabled, currentOffset < bufferData.count + bytesCached {
                let start = currentOffset - bytesCached
                let end = min(currentOffset + requestedLength - bytesCached, bufferData.count)
                if start >= end {
                    FileLog.shared.addMessage("MediaExporterResourceLoaderDelegate: try to read from memory with wrong indeces: \(start):\(end)")
                    return false
                }
                let dataRequested = bufferData.subdata(in: start..<end)
                dataRequest.respond(with: dataRequested)
                return dataRequest.currentOffset >= requestedLength + requestedOffset
            }
            return false
        }

        // Data length to be loaded into memory with maximum size of readDataLimit.
        let bytesToRespond = min(bytesCached - currentOffset, requestedLength, readDataLimit)

        // Read data from disk and pass it to the dataRequest
        guard let data = fileHandle.readData(withOffset: currentOffset, forLength: bytesToRespond) else { return false }
        dataRequest.respond(with: data)

        return dataRequest.currentOffset >= requestedLength + requestedOffset
    }

    private func writeBufferDataToFileIfNeeded() {
        lock.lock()
        defer { lock.unlock() }

        guard bufferData.count >= downloadBufferLimit else { return }

        do {
            try fileHandle.append(data: bufferData)
            bufferData = Data()
        } catch {
            FileLog.shared.addMessage("MediaExporterResourceLoaderDelegate: failed to write data to file: \(error)")
            invalidateAndCancelSession()
        }
    }

    func releaseIfDownloadComplete() {
        if isDownloadComplete {
            invalidateAndCancelSession(shouldResetData: false)
        }
    }

    private func downloadComplete() {
        processPendingRequests()

        isDownloadComplete = true
        let contentType = self.response?.mimeType
        callbackQueue.async {
            self.callback?(.completed, contentType, Int64(self.fileHandle.fileSize), Int64(self.fileHandle.fileSize))
        }
    }

    private func verifyResponse() -> NSError? {
        guard let response = response as? HTTPURLResponse else { return nil }

        let shouldVerifyDownloadedFileSize = MediaExporterItemConfiguration.shouldVerifyDownloadedFileSize
        let minimumExpectedFileSize = MediaExporterItemConfiguration.minimumExpectedFileSize
        var error: NSError?

        if response.statusCode >= 400 {
            error = NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: [NSDebugDescriptionErrorKey: "Failed downloading asset. Reason: response status code \(response.statusCode)."])
        } else if shouldVerifyDownloadedFileSize && response.expectedContentLength != -1 && response.expectedContentLength != fileHandle.fileSize {
            error = NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: [NSDebugDescriptionErrorKey: "Failed downloading asset. Reason: wrong file size, expected: \(response.expectedContentLength), actual: \(fileHandle.fileSize)."])
        } else if minimumExpectedFileSize > 0 && minimumExpectedFileSize > fileHandle.fileSize {
            error = NSError(domain: NSURLErrorDomain, code: NSURLErrorZeroByteResource, userInfo: [NSDebugDescriptionErrorKey: "Failed downloading asset. Reason: file size \(fileHandle.fileSize) is smaller than minimumExpectedFileSize"])
        }

        return error
    }

    private func shouldRetryWithoutUserAgent(error: NSError) -> Bool {
        // Only retry if we haven't already retried without User-Agent and the error is a status code >= 400
        return !hasRetriedWithoutUserAgent && (error.code == NSURLErrorResourceUnavailable || error.code == NSURLErrorZeroByteResource)
    }

    private func retryWithoutUserAgent(originalURL: URL?) {
        guard let originalURL = originalURL else {
            FileLog.shared.addMessage("MediaExporterResourceLoaderDelegate: Cannot retry without User-Agent - no original URL")
            return
        }

        FileLog.shared.addMessage("MediaExporterResourceLoaderDelegate: Retrying without User-Agent header for URL: \(originalURL)")

        fileHandle.close()

        invalidateAndCancelSession(shouldResetData: false)

        response = nil
        bufferData = Data()

        fileHandle = MediaFileHandle(filePath: saveFilePath)

        startDataRequest(with: originalURL, retryWithoutUserAgent: true)
    }

    private func downloadFailed(with error: Error) {
        FileLog.shared.addMessage("MediaExporterResourceLoaderDelegate: Download failed with error: \(error)")
        invalidateAndCancelSession(error: error)
        let contentType = self.response?.mimeType
        callbackQueue.async { [weak self] in
            guard let self else { return }
            self.callback?(.failed(error), contentType, 0, 0)
        }
    }

    @objc private func handleAppWillTerminate() {
        invalidateAndCancelSession(shouldResetData: false)
    }
}
#endif
