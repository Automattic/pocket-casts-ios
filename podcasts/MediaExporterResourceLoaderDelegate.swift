import Foundation
import AVFoundation
import UIKit
import PocketCastsServer

#if !os(watchOS)
/// MediaExporterItemConfiguration global configuration.
private enum MediaExporterItemConfiguration {
    /// How much data is downloaded in memory before stored on a file.
    public static var downloadBufferLimit: Int = 128.KB

    /// How much data is allowed to be read in memory at a time.
    public static var readDataLimit: Int = 10.MB

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
final class MediaExporterResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    private let lock = NSLock()

    private var bufferData = Data()
    private let downloadBufferLimit = MediaExporterItemConfiguration.downloadBufferLimit
    private let readDataLimit = MediaExporterItemConfiguration.readDataLimit

    private lazy var fileHandle = MediaFileHandle(filePath: saveFilePath)

    private var session: URLSession?
    private var response: URLResponse?
    private let queue = DispatchQueue(label: "com.pocketcasts.MediaExporterResourceLoaderDelegate", qos: .userInitiated, attributes: .concurrent)
    private var pendingRequests: Set<AVAssetResourceLoadingRequest> {
        get { queue.sync { return pendingRequestsValue } }
        set { queue.async(flags: .barrier) { [weak self] in self?.pendingRequestsValue = newValue } }
    }
    private var pendingRequestsValue = Set<AVAssetResourceLoadingRequest>()
    private var isDownloadComplete = false

    private let saveFilePath: String
    private let callback: FileExporterProgressReport?

    enum FileExportStatus {
        case downloading
        case complete
        case error
    }

    typealias FileExporterProgressReport = (_ status: FileExportStatus, _ downloaded: Int64, _ total: Int64) -> ()

    // MARK: Init
    init(saveFilePath: String, callback: FileExporterProgressReport?) {
        self.saveFilePath = saveFilePath
        self.callback = callback
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }

    deinit {
        invalidateAndCancelSession(shouldResetData: false)
    }

    // MARK: AVAssetResourceLoaderDelegate

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url else {
            return false
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.scheme = "https"
        let realURL = components.url!
        if session == nil {
            // If we're playing from an url, we need to download the file.
            // We start loading the file on first request only.
            startDataRequest(with: realURL)
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
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.callback?(.downloading, Int64(self.fileHandle.fileSize), dataTask.countOfBytesExpectedToReceive)
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

        if bufferData.count > 0 {
            fileHandle.append(data: bufferData)
        }

        let error = verifyResponse()

        guard error == nil else {
            downloadFailed(with: error!)
            return
        }

        downloadComplete()
    }

    // MARK: Internal methods

    func startDataRequest(with url: URL) {
        guard session == nil else { return }

        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue(ServerConstants.Values.appUserAgent, forHTTPHeaderField: ServerConstants.HttpHeaders.userAgent)
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        session?.dataTask(with: urlRequest).resume()
    }

    func invalidateAndCancelSession(shouldResetData: Bool = true) {
        session?.invalidateAndCancel()
        session = nil

        if shouldResetData {
            bufferData = Data()
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
        guard bytesCached > currentOffset else { return false }

        // Data length to be loaded into memory with maximum size of readDataLimit.
        let bytesToRespond = min(bytesCached - currentOffset, requestedLength, readDataLimit)

        // Read data from disk and pass it to the dataRequest
        guard let data = fileHandle.readData(withOffset: currentOffset, forLength: bytesToRespond) else { return false }
        dataRequest.respond(with: data)

        return bytesCached >= requestedLength + requestedOffset
    }

    private func writeBufferDataToFileIfNeeded() {
        lock.lock()
        defer { lock.unlock() }

        guard bufferData.count >= downloadBufferLimit else { return }

        fileHandle.append(data: bufferData)
        bufferData = Data()
    }

    private func downloadComplete() {
        processPendingRequests()

        isDownloadComplete = true

        DispatchQueue.main.async {
            self.callback?(.complete, Int64(self.fileHandle.fileSize), Int64(self.fileHandle.fileSize))
        }
    }

    private func verifyResponse() -> NSError? {
        guard let response = response as? HTTPURLResponse else { return nil }

        let shouldVerifyDownloadedFileSize = MediaExporterItemConfiguration.shouldVerifyDownloadedFileSize
        let minimumExpectedFileSize = MediaExporterItemConfiguration.minimumExpectedFileSize
        var error: NSError?

        if response.statusCode >= 400 {
            error = NSError(domain: "Failed downloading asset. Reason: response status code \(response.statusCode).", code: response.statusCode, userInfo: nil)
        } else if shouldVerifyDownloadedFileSize && response.expectedContentLength != -1 && response.expectedContentLength != fileHandle.fileSize {
            error = NSError(domain: "Failed downloading asset. Reason: wrong file size, expected: \(response.expectedContentLength), actual: \(fileHandle.fileSize).", code: response.statusCode, userInfo: nil)
        } else if minimumExpectedFileSize > 0 && minimumExpectedFileSize > fileHandle.fileSize {
            error = NSError(domain: "Failed downloading asset. Reason: file size \(fileHandle.fileSize) is smaller than minimumExpectedFileSize", code: response.statusCode, userInfo: nil)
        }

        return error
    }

    private func downloadFailed(with error: Error) {
        invalidateAndCancelSession()

        DispatchQueue.main.async {
            self.callback?(.error, 0, 0)
        }
    }

    @objc private func handleAppWillTerminate() {
        invalidateAndCancelSession(shouldResetData: false)
    }
}
#endif
