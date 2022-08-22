import Foundation
import PocketCastsServer

public extension SubscriptionHelper {
    class func subscriptionFrequency() -> String {
        let frequency = UserDefaults.standard.integer(forKey: ServerConstants.UserDefaults.subscriptionFrequency)
        return readableSubscriptionFrequency(frequency: frequency)
    }

    class func readableSubscriptionFrequency(frequency: Int) -> String {
        switch frequency {
        case SubscriptionFrequency.monthly.rawValue:
            return L10n.Localizable.monthly
        case SubscriptionFrequency.yearly.rawValue:
            return L10n.Localizable.yearly
        default:
            return ""
        }
    }
}

public extension APIError {
    var localizedDescription: String {
        switch self {
        case .UNKNOWN: return L10n.Localizable.serverErrorUnknown
        case .INCORRECT_PASSWORD: return L10n.Localizable.serverErrorLoginPasswordIncorrect
        case .PERMISSION_DENIED: return L10n.Localizable.serverErrorLoginPermissionDeniedNotAdmin
        case .ACCOUNT_LOCKED: return L10n.Localizable.serverErrorLoginAccountLocked
        case .BLANK_EMAIL: return L10n.Localizable.serverErrorLoginEmailBlank
        case .BLANK_PASSWORD: return L10n.Localizable.serverErrorLoginPasswordBlank
        case .EMAIL_NOT_FOUND: return L10n.Localizable.serverErrorLoginEmailNotFound
        case .THANKS_FOR_SIGNING_UP: return L10n.Localizable.serverMessageLoginThanksSigningUp
        case .UNABLE_TO_CREATE_ACCOUNT: return L10n.Localizable.serverErrorLoginUnableToCreateAccount
        case .PASSWORD_INVALID: return L10n.Localizable.serverErrorLoginPasswordInvalid
        case .EMAIL_INVALID: return L10n.Localizable.serverErrorLoginEmailInvalid
        case .EMAIL_TAKEN: return L10n.Localizable.serverErrorLoginEmailTaken
        case .USER_REGISTER_FAILED: return L10n.Localizable.serverErrorLoginUserRegisterFailed
        case .FILES_INVALID_CONTENT_TYPE: return L10n.Localizable.serverErrorFilesInvalidContentType
        case .FILES_INVALID_USER: return L10n.Localizable.serverErrorFilesInvalidUser
        case .FILES_FILE_LARGER_THAN_SPECIFIED_LIMIT: return L10n.Localizable.serverErrorFilesFileTooLarge
        case .FILES_EXCEEDS_STORAGE: return L10n.Localizable.serverErrorFilesStorageLimitExceeded
        case .FILES_TITLE_REQUIRED: return L10n.Localizable.serverErrorFilesTitleRequired
        case .FILES_FILE_UUID_REQUIRED: return L10n.Localizable.serverErrorFilesUuidRequired
        case .FILES_FILE_UPLOAD_FAILED: return L10n.Localizable.serverErrorFilesUploadFailedGeneric
        case .PROMO_ALREADY_PLUS: return L10n.Localizable.serverErrorPromoAlreadyPlus
        case .PROMO_CODE_EXPIRED_OR_INVALID: return L10n.Localizable.serverErrorPromoCodeExpiredOrInvalid
        case .PROMO_ALREADY_REDEEMED: return L10n.Localizable.serverErrorPromoAlreadyRedeemed
        case .NO_CONNECTION: return L10n.Localizable.playerErrorInternetConnection
        }
    }
}

public extension AutoAddLimitReachedAction {
    func description(short: Bool = false) -> String {
        switch self {
        case .stopAdding:
            return short ? L10n.Localizable.autoAddToUpNextStopShort : L10n.Localizable.autoAddToUpNextStop
        case .addToTopOnly:
            return short ? L10n.Localizable.autoAddToUpNextTopOnlyShort : L10n.Localizable.autoAddToUpNextTopOnly
        }
    }
}
