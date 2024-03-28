import Foundation
import PocketCastsServer
import PocketCastsDataModel

public extension SubscriptionHelper {
    class func subscriptionFrequency() -> String {
        let frequency = UserDefaults.standard.integer(forKey: ServerConstants.UserDefaults.subscriptionFrequency)
        return readableSubscriptionFrequency(frequency: frequency)
    }

    class func readableSubscriptionFrequency(frequency: Int) -> String {
        switch frequency {
        case SubscriptionFrequency.monthly.rawValue:
            return L10n.monthly
        case SubscriptionFrequency.yearly.rawValue:
            return L10n.yearly
        default:
            return ""
        }
    }
}

public extension APIError {
    var localizedDescription: String {
        switch self {
        case .UNKNOWN: return L10n.serverErrorUnknown
        case .INCORRECT_PASSWORD: return L10n.serverErrorLoginPasswordIncorrect
        case .PERMISSION_DENIED: return L10n.serverErrorLoginPermissionDeniedNotAdmin
        case .ACCOUNT_LOCKED: return L10n.serverErrorLoginAccountLocked
        case .BLANK_EMAIL: return L10n.serverErrorLoginEmailBlank
        case .BLANK_PASSWORD: return L10n.serverErrorLoginPasswordBlank
        case .EMAIL_NOT_FOUND: return L10n.serverErrorLoginEmailNotFound
        case .THANKS_FOR_SIGNING_UP: return L10n.serverMessageLoginThanksSigningUp
        case .UNABLE_TO_CREATE_ACCOUNT: return L10n.serverErrorLoginUnableToCreateAccount
        case .PASSWORD_INVALID: return L10n.serverErrorLoginPasswordInvalid
        case .EMAIL_INVALID: return L10n.serverErrorLoginEmailInvalid
        case .EMAIL_TAKEN: return L10n.serverErrorLoginEmailTaken
        case .USER_REGISTER_FAILED: return L10n.serverErrorLoginUserRegisterFailed
        case .FILES_INVALID_CONTENT_TYPE: return L10n.serverErrorFilesInvalidContentType
        case .FILES_INVALID_USER: return L10n.serverErrorFilesInvalidUser
        case .FILES_FILE_LARGER_THAN_SPECIFIED_LIMIT: return L10n.serverErrorFilesFileTooLarge
        case .FILES_EXCEEDS_STORAGE: return L10n.serverErrorFilesStorageLimitExceeded
        case .FILES_TITLE_REQUIRED: return L10n.serverErrorFilesTitleRequired
        case .FILES_FILE_UUID_REQUIRED: return L10n.serverErrorFilesUuidRequired
        case .FILES_FILE_UPLOAD_FAILED: return L10n.serverErrorFilesUploadFailedGeneric
        case .PROMO_ALREADY_PLUS: return L10n.serverErrorPromoAlreadyPlus
        case .PROMO_CODE_EXPIRED_OR_INVALID: return L10n.serverErrorPromoCodeExpiredOrInvalid
        case .PROMO_ALREADY_REDEEMED: return L10n.serverErrorPromoAlreadyRedeemed
        case .NO_CONNECTION: return L10n.playerErrorInternetConnection
        case .TOKEN_DEAUTH: return L10n.clientErrorTokenDeauth
        }
    }
}

public extension AutoAddLimitReachedAction {
    func description(short: Bool = false) -> String {
        switch self {
        case .stopAdding:
            return short ? L10n.autoAddToUpNextStopShort : L10n.autoAddToUpNextStop
        case .addToTopOnly:
            return short ? L10n.autoAddToUpNextTopOnlyShort : L10n.autoAddToUpNextTopOnly
        }
    }
}
