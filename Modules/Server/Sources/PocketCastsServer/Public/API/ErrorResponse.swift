import Foundation

public enum APIError: String, Error {
    case UNKNOWN = "unknown"
    case INCORRECT_PASSWORD = "login_password_incorrect"
    case PERMISSION_DENIED = "login_permission_denied_not_admin"
    case ACCOUNT_LOCKED = "login_account_locked"
    case BLANK_EMAIL = "login_email_blank"
    case BLANK_PASSWORD = "login_password_blank"
    case EMAIL_NOT_FOUND = "login_email_not_found"
    case THANKS_FOR_SIGNING_UP = "login_thanks_signing_up"
    case UNABLE_TO_CREATE_ACCOUNT = "login_unable_to_create_account"
    case PASSWORD_INVALID = "login_password_invalid"
    case EMAIL_INVALID = "login_email_invalid"
    case EMAIL_TAKEN = "login_email_taken"
    case USER_REGISTER_FAILED = "login_user_register_failed"
    case FILES_INVALID_CONTENT_TYPE = "files_invalid_content_type"
    case FILES_INVALID_USER = "files_invalid_user"
    case FILES_FILE_LARGER_THAN_SPECIFIED_LIMIT = "files_file_too_large"
    case FILES_EXCEEDS_STORAGE = "files_storage_limit_exceeded"
    case FILES_TITLE_REQUIRED = "files_title_required"
    case FILES_FILE_UUID_REQUIRED = "files_uuid_required"
    case FILES_FILE_UPLOAD_FAILED = "files_upload_failed_generic"
    case PROMO_ALREADY_PLUS = "promo_already_plus"
    case PROMO_CODE_EXPIRED_OR_INVALID = "promo_code_expired_or_invalid"
    case PROMO_ALREADY_REDEEMED = "promo_already_redeemed"
    case NO_CONNECTION = "no_connection" // This error doesn't map to a code provided by the API but is added locallay for client errors.
    case TOKEN_REFRESH_FAILED = "token_refresh_failed"
}
