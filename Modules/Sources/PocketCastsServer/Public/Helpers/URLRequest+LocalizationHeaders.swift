import Foundation
import PocketCastsUtils

extension URLRequest {
    public mutating func addLocalizationHeaders() {
        guard
            let provider = LocalizationHelper.provider,
            let host = url?.host,
            provider.allowedHosts.contains(host)
        else {
            return
        }
        if let userRegion = provider.userRegion {
            setValue(userRegion, forHTTPHeaderField: ServerConstants.HttpHeaders.userRegion)
        }
        setValue(provider.appLanguage, forHTTPHeaderField: ServerConstants.HttpHeaders.appLanguage)
    }
}
