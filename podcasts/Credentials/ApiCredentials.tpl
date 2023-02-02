/// API Credentials. Generated on %{timestamp}
///
struct ApiCredentials {

    /// Zendesk App ID
    ///
    static let zendeskAPIKey = "%{zendesk_api_key}"

    /// Zendesk URL
    ///
    static let zendeskUrl = "%{zendesk_url}"

    /// WordPress.com Secret
    ///
    static let dotcomSecret = "%{dotcom_secret}"

    /// Encrypted Logging Public Key
    ///
    static let loggingEncryptionKey = "%{encrypted_log_key}"

    /// Sharing Server Secret
    ///
    static let sharingServerSecret = "%{sharing_server_secret}"

    /// Sentry Secret
    ///
    static let sentryDSN = "%{sentry_dsn}"

    /// Google Sign In
    ///
    static let googleSignInSecret = "%{google_sign_in_secret}"
    static let googleSignInServerClientId = "%{google_sign_in_server_client_id}"
}
