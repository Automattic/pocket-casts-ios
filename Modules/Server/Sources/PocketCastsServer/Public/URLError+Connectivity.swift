import Foundation

extension NSError {
    var isConnectivityError: Bool {
        guard domain == NSURLErrorDomain else {
            return false
        }
        switch code {
        case URLError.notConnectedToInternet.rawValue,
             URLError.networkConnectionLost.rawValue,
             URLError.cannotFindHost.rawValue,
             URLError.cannotConnectToHost.rawValue,
             URLError.dnsLookupFailed.rawValue,
             URLError.dataNotAllowed.rawValue,
             URLError.internationalRoamingOff.rawValue,
             URLError.callIsActive.rawValue:
            return true
        default:
            return false
        }
    }
}
