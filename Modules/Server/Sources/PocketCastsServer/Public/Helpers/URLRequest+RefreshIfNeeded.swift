import Foundation

public extension URLRequest {

    mutating func setRefreshHeadersUsing(cachedResponse: CachedURLResponse) {
        if let etag = cachedResponse.response.etag {
            self.setValue(etag, forHTTPHeaderField: ServerConstants.HttpHeaders.ifNoneMatch)
        }

        if let lastModified = cachedResponse.response.lastModified {
            self.setValue(lastModified, forHTTPHeaderField: ServerConstants.HttpHeaders.ifModifiedSince)
        }
    }
}
