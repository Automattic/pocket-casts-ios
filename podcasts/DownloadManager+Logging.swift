import PocketCastsDataModel

extension DownloadManager {
    func logDownload(_ episode: BaseEpisode, failure: FailureReason, extraProperties: [String: Any?] = [:]) {
        let properties = ["reason": failure.localizedDescription].merging(extraProperties) { (current, _) in return current }
        AnalyticsEpisodeHelper.shared.downloadFailed(episodeUUID: episode.uuid,
                                                     podcastUUID: episode.parentIdentifier(),
                                                     extraProperties: properties.compactMapValues({ $0 }))
    }

    func logDownload(_ episode: BaseEpisode, failure: FailureReason, metrics: URLSessionTaskMetrics, session: URLSession) {
        let errorCode: Int?
        let errorDomain: String?
        if case let DownloadManager.FailureReason.unknown(error) = failure {
            errorCode = error.code
            errorDomain = error.domain
        } else {
            errorCode = nil
            errorDomain = nil
        }

        let statusCode: Int?
        if case let DownloadManager.FailureReason.statusCode(code) = failure {
            statusCode = code
        } else {
            statusCode = metrics.transactionMetrics.last?.response?.extractStatusCode()
        }

        let fileSize: Int64?
        if case let DownloadManager.FailureReason.suspiciousContent(size) = failure {
            fileSize = size
        } else {
            fileSize = nil
        }

        let contentType = metrics.transactionMetrics.last?.response?.mimeType
        let redirectCount = metrics.redirectCount
        let duration = Int(metrics.taskInterval.duration * 1000.0) // Convert to milliseconds Int for logging
        let isProxy = metrics.transactionMetrics.last?.isProxyConnection == true
        let isCellular = metrics.transactionMetrics.last?.isCellular == true
        let isMultipath = metrics.transactionMetrics.last?.isMultipath == true
        let tlsCipherSuite = metrics.transactionMetrics.last?.negotiatedTLSCipherSuite?.debugDescription
        let expectedContentLength = metrics.transactionMetrics.last?.response?.expectedContentLength
        let responseBodyBytesReceived = metrics.transactionMetrics.last?.countOfResponseBodyBytesReceived
        let inBackground = session == cellularBackgroundSession || session == wifiOnlyBackgroundSession

        logDownload(episode,
                    failure: failure,
                    extraProperties: [
            "http_status_code": statusCode,
            "http_content_type": contentType,
            "error_code": errorCode,
            "error_domain": errorDomain,
            "file_size": fileSize,
            "redirects": redirectCount,
            "is_proxy": isProxy,
            "is_cellular": isCellular,
            "is_multipath": isMultipath,
            "tls_cipher_suite": tlsCipherSuite,
            "duration": duration,
            "expected_content_length": expectedContentLength,
            "response_body_bytes_received": responseBodyBytesReceived,
            "in_background": inBackground
        ])
    }
}

extension tls_ciphersuite_t: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .RSA_WITH_3DES_EDE_CBC_SHA:
            return "RSA_WITH_3DES_EDE_CBC_SHA"
        case .RSA_WITH_AES_128_CBC_SHA:
            return "RSA_WITH_AES_128_CBC_SHA"
        case .RSA_WITH_AES_256_CBC_SHA:
            return "RSA_WITH_AES_256_CBC_SHA"
        case .RSA_WITH_AES_128_GCM_SHA256:
            return "RSA_WITH_AES_128_GCM_SHA256"
        case .RSA_WITH_AES_256_GCM_SHA384:
            return "RSA_WITH_AES_256_GCM_SHA384"
        case .RSA_WITH_AES_128_CBC_SHA256:
            return "RSA_WITH_AES_128_CBC_SHA256"
        case .RSA_WITH_AES_256_CBC_SHA256:
            return "RSA_WITH_AES_256_CBC_SHA256"
        case .ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA:
            return "ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA"
        case .ECDHE_ECDSA_WITH_AES_128_CBC_SHA:
            return "ECDHE_ECDSA_WITH_AES_128_CBC_SHA"
        case .ECDHE_ECDSA_WITH_AES_256_CBC_SHA:
            return "ECDHE_ECDSA_WITH_AES_256_CBC_SHA"
        case .ECDHE_RSA_WITH_3DES_EDE_CBC_SHA:
            return "ECDHE_RSA_WITH_3DES_EDE_CBC_SHA"
        case .ECDHE_RSA_WITH_AES_128_CBC_SHA:
            return "ECDHE_RSA_WITH_AES_128_CBC_SHA"
        case .ECDHE_RSA_WITH_AES_256_CBC_SHA:
            return "ECDHE_RSA_WITH_AES_256_CBC_SHA"
        case .ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:
            return "ECDHE_ECDSA_WITH_AES_128_CBC_SHA256"
        case .ECDHE_ECDSA_WITH_AES_256_CBC_SHA384:
            return "ECDHE_ECDSA_WITH_AES_256_CBC_SHA384"
        case .ECDHE_RSA_WITH_AES_128_CBC_SHA256:
            return "ECDHE_RSA_WITH_AES_128_CBC_SHA256"
        case .ECDHE_RSA_WITH_AES_256_CBC_SHA384:
            return "ECDHE_RSA_WITH_AES_256_CBC_SHA384"
        case .ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:
            return "ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
        case .ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:
            return "ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
        case .ECDHE_RSA_WITH_AES_128_GCM_SHA256:
            return "ECDHE_RSA_WITH_AES_128_GCM_SHA256"
        case .ECDHE_RSA_WITH_AES_256_GCM_SHA384:
            return "ECDHE_RSA_WITH_AES_256_GCM_SHA384"
        case .ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:
            return "ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256"
        case .ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:
            return "ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
        case .AES_128_GCM_SHA256:
            return "AES_128_GCM_SHA256"
        case .AES_256_GCM_SHA384:
            return "AES_256_GCM_SHA384"
        case .CHACHA20_POLY1305_SHA256:
            return "CHACHA20_POLY1305_SHA256"
        @unknown default:
            return "UNKNOWN_SUITE"
        }
    }
}
