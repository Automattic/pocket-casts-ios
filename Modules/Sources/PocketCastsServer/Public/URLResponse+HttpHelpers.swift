import Foundation
import PocketCastsUtils

extension URLResponse {
    var expires: String? {
        (self as? HTTPURLResponse)?.allHeaderFields[ServerConstants.HttpHeaders.expires] as? String
    }

    var expiresDate: Date? {
        DateFormatHelper.sharedHelper.httpDate(expires)
    }

    var cacheControl: String? {
        (self as? HTTPURLResponse)?.allHeaderFields[ServerConstants.HttpHeaders.cacheControl] as? String
    }

    // The following directives indicate the response must not be cached.
    var cacheControlNoCache: Bool {
        guard let cacheControl = cacheControl else {
            return false
        }
        return cacheControl.contains("no-cache") || cacheControl.contains("no-store") || cacheControl.contains("must-revalidate")
    }

    // The number of seconds from the time of the request the data is refresh.
    var cacheControlMaxAge: Int? {
        guard let cacheControl = cacheControl else {
            return nil
        }
        // Split into directives ["public", "max-age=604800", "immutable"]
        let directives = cacheControl.replacingOccurrences(of: " ", with: "").split(separator: ",")
        // Split into parts ["max-age", "604800"]
        if let value = directives.map({ $0.split(separator: "=") }).first(where: { $0.first == "max-age" })?.last {
            return Int(String(value))
        } else {
            return nil
        }
    }

    var date: Date? {
        guard let httpResponse = self as? HTTPURLResponse else {
            return nil
        }
        let dateString = httpResponse.allHeaderFields[ServerConstants.HttpHeaders.date] as? String
        return DateFormatHelper.sharedHelper.httpDate(dateString)
    }

    var etag: String? {
        (self as? HTTPURLResponse)?.allHeaderFields[ServerConstants.HttpHeaders.etag] as? String
    }

    var lastModified: String? {
        (self as? HTTPURLResponse)?.allHeaderFields[ServerConstants.HttpHeaders.lastModified] as? String
    }

    // Find the cache expiry date from either the Cache-Control or Expires
    func cacheExpiryDate() -> Date? {
        // check http header Cache-Control no-cache
        if cacheControlNoCache {
            return nil
        }
        // check http header Cache-Control max-age
        else if let date = date, let maxAge = cacheControlMaxAge, maxAge > 0 {
            return date.addingTimeInterval(TimeInterval(maxAge))
        }
        // check http header Expires
        else if let expiresDate = expiresDate {
            return expiresDate
        }
        return nil
    }

    public func extractStatusCode() -> Int {
        if let httpResponse = self as? HTTPURLResponse {
            return httpResponse.statusCode
        }

        return 0
    }
}
