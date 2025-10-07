import Foundation
import PocketCastsUtils

extension URLRequest {
    public mutating func addLocalizationHeaders() {
        guard FeatureFlag.enableLocalizationHeaders.enabled else {
            return
        }
        if let userRegion = LocalizationHelper.provider?.userRegion {
            setValue(userRegion, forHTTPHeaderField: ServerConstants.HttpHeaders.userRegion)
        }
        if let appLanguage = LocalizationHelper.provider?.appLanguage {
            setValue(appLanguage, forHTTPHeaderField: ServerConstants.HttpHeaders.appLanguage)
        }
    }
}
