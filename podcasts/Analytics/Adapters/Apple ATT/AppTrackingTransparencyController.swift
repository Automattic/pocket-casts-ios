import AppTrackingTransparency
import PocketCastsUtils

protocol AppTrackingTransparencyProvider {
    func shouldShowPrompt() -> Bool
    func userGaveConsent() -> Bool
    func userDeniedConsent() -> Bool
    func userSawPrompt() -> Bool
    func promptConsentAlert() async -> Bool
}

class AppTrackingTransparencyController: AppTrackingTransparencyProvider {
    static let shared = AppTrackingTransparencyController()

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
        return ATTrackingManager.trackingAuthorizationStatus.isDenied
    }

    @discardableResult
    func promptConsentAlert() async -> Bool {
        guard shouldShowPrompt() else {
            return false
        }
        let authorizationStatus = await ATTrackingManager.requestTrackingAuthorization()
        FileLog.shared.addMessage("ATT Tracking request authorization: \(authorizationStatus.stringValue)")
        return true
    }
}

extension ATTrackingManager.AuthorizationStatus {
    fileprivate var isAuthorized: Bool {
        self == .authorized
    }

    fileprivate var isDenied: Bool {
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
