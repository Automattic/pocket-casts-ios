import AppTrackingTransparency
import PocketCastsUtils
import Combine

protocol AppTrackingTransparencyProvider {
    var authorizationStatusUpdated: ((Bool, String) -> Void)? { get set }

    func shouldShowPrompt() -> Bool
    func userGaveConsent() -> Bool
    func userDeniedConsent() -> Bool
    func promptConsentAlert() async -> Bool
}

class AppTrackingTransparencyController: AppTrackingTransparencyProvider {
    static let shared = AppTrackingTransparencyController()

    var authorizationStatusUpdated: ((Bool, String) -> Void)?

    func shouldShowPrompt() -> Bool {
        return ATTrackingManager.trackingAuthorizationStatus == .notDetermined
    }

    func userSawPrompt() -> Bool {
        return ATTrackingManager.trackingAuthorizationStatus != .notDetermined
    }

    func userGaveConsent() -> Bool {
        return ATTrackingManager.trackingAuthorizationStatus.isAuthorized
    }

    func userDeniedConsent() -> Bool {
        return ATTrackingManager.trackingAuthorizationStatus.idDenied
    }

    @discardableResult
    func promptConsentAlert() async -> Bool {
        guard shouldShowPrompt() else {
            return false
        }
        let authorizationStatus = await ATTrackingManager.requestTrackingAuthorization()
        FileLog.shared.addMessage("ATTTracking request authorization: \(authorizationStatus.stringValue)")
        authorizationStatusUpdated?(authorizationStatus.isAuthorized, authorizationStatus.stringValue)
        return true
    }
}

extension ATTrackingManager.AuthorizationStatus {
    fileprivate var isAuthorized: Bool {
        self == .authorized
    }

    fileprivate var idDenied: Bool {
        self == .denied
    }

    fileprivate var stringValue: String {
        switch self {
        case .notDetermined:
            "Not Determined"
        case .restricted:
            "Restricted"
        case .denied:
            "Denied"
        case .authorized:
            "Authorized"
        @unknown default:
            "Unknown"
        }
    }
}
