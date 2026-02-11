import AuthenticationServices
import Foundation
import PocketCastsUtils

// MARK: - Errors

enum YouTubePlaylistAuthError: LocalizedError {
    case canceled
    case noTokenReturned
    case tokenExchangeFailed(Error)
    case keychainFailure

    var errorDescription: String? {
        switch self {
        case .canceled:
            return "Sign in was canceled."
        case .noTokenReturned:
            return "No access token was returned from YouTube."
        case .tokenExchangeFailed(let underlying):
            return "Token exchange failed: \(underlying.localizedDescription)"
        case .keychainFailure:
            return "Failed to save credentials securely."
        }
    }
}

// MARK: - Token Storage

private enum YouTubePlaylistKeychainKey {
    static let accessToken = "YouTubePlaylistAccessToken"
    static let refreshToken = "YouTubePlaylistRefreshToken"
    static let expiresAt = "YouTubePlaylistTokenExpiresAt"
}

// MARK: - YouTubePlaylistAuthManager

/// Manages YouTube OAuth 2.0 authentication for playlist access
///
/// Uses `ASWebAuthenticationSession` for OAuth flow with PKCE security.
/// Tokens are persisted securely in Keychain.
@MainActor
final class YouTubePlaylistAuthManager: NSObject, ObservableObject {

    static let shared = YouTubePlaylistAuthManager()

    // MARK: - Published State

    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var isBusy: Bool = false
    @Published var authError: Error?

    // MARK: - Configuration

    private let clientID = Bundle.main.object(forInfoDictionaryKey: "YouTubeOAuthClientID") as? String ?? ""
    private let redirectURI = Bundle.main.object(forInfoDictionaryKey: "YouTubeOAuthRedirectURI") as? String ?? ""

    private let scope = "https://www.googleapis.com/auth/youtube.readonly"
    private let authEndpoint = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
    private let tokenEndpoint = URL(string: "https://oauth2.googleapis.com/token")!

    // MARK: - Private Storage

    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiresAt: Date?

    private var authSession: ASWebAuthenticationSession?

    // MARK: - Init

    private override init() {
        super.init()
        loadFromKeychain()
    }

    // MARK: - Public API

    /// True when a valid (non-expired) access token is available
    var hasValidToken: Bool {
        guard let token = accessToken, !token.isEmpty else { return false }
        if let expiry = tokenExpiresAt {
            return expiry.timeIntervalSinceNow > 60
        }
        return true
    }

    /// Returns a fresh access token, refreshing if necessary
    func validAccessToken() async throws -> String {
        if hasValidToken, let token = accessToken { return token }
        try await refreshAccessToken()
        guard let token = accessToken, !token.isEmpty else {
            throw YouTubePlaylistAuthError.noTokenReturned
        }
        return token
    }

    /// Launches the OAuth sign-in flow
    func signIn(from contextProvider: ASWebAuthenticationPresentationContextProviding) async throws {
        isBusy = true
        authError = nil
        defer { isBusy = false }

        print("[YouTubePlaylistAuth] Starting sign-in...")
        print("[YouTubePlaylistAuth] Client ID: \(clientID)")
        print("[YouTubePlaylistAuth] Redirect URI: \(redirectURI)")

        let state = UUID().uuidString
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        var components = URLComponents(url: authEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
        ]
        guard let authURL = components.url else {
            print("[YouTubePlaylistAuth] Failed to build auth URL")
            throw YouTubePlaylistAuthError.noTokenReturned
        }
        print("[YouTubePlaylistAuth] Auth URL: \(authURL)")

        guard let scheme = URL(string: redirectURI)?.scheme else {
            throw YouTubePlaylistAuthError.noTokenReturned
        }

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: scheme) { url, error in
                if let error = error {
                    if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                        continuation.resume(throwing: YouTubePlaylistAuthError.canceled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let url else {
                    continuation.resume(throwing: YouTubePlaylistAuthError.noTokenReturned)
                    return
                }
                continuation.resume(returning: url)
            }
            session.presentationContextProvider = contextProvider
            session.prefersEphemeralWebBrowserSession = false
            self.authSession = session
            session.start()
        }

        // Validate state to prevent CSRF
        print("[YouTubePlaylistAuth] Callback URL: \(callbackURL)")
        let callbackItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems
        print("[YouTubePlaylistAuth] Callback items: \(callbackItems ?? [])")

        // Check for error in callback
        if let error = callbackItems?.first(where: { $0.name == "error" })?.value {
            let errorDesc = callbackItems?.first(where: { $0.name == "error_description" })?.value ?? "Unknown"
            print("[YouTubePlaylistAuth] OAuth error: \(error) - \(errorDesc)")
            throw YouTubePlaylistAuthError.noTokenReturned
        }

        guard callbackItems?.first(where: { $0.name == "state" })?.value == state,
              let code = callbackItems?.first(where: { $0.name == "code" })?.value else {
            print("[YouTubePlaylistAuth] State mismatch or no code in callback")
            throw YouTubePlaylistAuthError.noTokenReturned
        }

        print("[YouTubePlaylistAuth] Got auth code, exchanging for tokens...")
        try await exchangeCodeForTokens(code: code, codeVerifier: codeVerifier)
        isSignedIn = true
    }

    /// Signs out and clears all stored credentials
    func signOut() {
        accessToken = nil
        refreshToken = nil
        tokenExpiresAt = nil
        isSignedIn = false
        clearKeychain()
    }

    // MARK: - Token Exchange

    private func exchangeCodeForTokens(code: String, codeVerifier: String) async throws {
        var request = URLRequest(url: tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // iOS apps don't use client_secret - PKCE provides security instead
        let body = [
            "code": code,
            "client_id": clientID,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code",
            "code_verifier": codeVerifier,
        ]
        request.httpBody = urlEncodedBody(body)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            try parseAndStoreTokens(from: data)
        } catch let e as YouTubePlaylistAuthError {
            throw e
        } catch {
            throw YouTubePlaylistAuthError.tokenExchangeFailed(error)
        }
    }

    private func refreshAccessToken() async throws {
        guard let refresh = refreshToken, !refresh.isEmpty else {
            isSignedIn = false
            throw YouTubePlaylistAuthError.noTokenReturned
        }

        var request = URLRequest(url: tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // iOS apps don't use client_secret
        let body = [
            "client_id": clientID,
            "refresh_token": refresh,
            "grant_type": "refresh_token",
        ]
        request.httpBody = urlEncodedBody(body)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            try parseAndStoreTokens(from: data)
        } catch let e as YouTubePlaylistAuthError {
            isSignedIn = false
            throw e
        } catch {
            isSignedIn = false
            throw YouTubePlaylistAuthError.tokenExchangeFailed(error)
        }
    }

    // MARK: - Token Parsing

    private struct TokenResponse: Decodable {
        let access_token: String
        let refresh_token: String?
        let expires_in: Int?
        let token_type: String?
    }

    private func parseAndStoreTokens(from data: Data) throws {
        // Debug: Log the raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[YouTubePlaylistAuth] Token response: \(jsonString)")
        }

        guard let response = try? JSONDecoder().decode(TokenResponse.self, from: data),
              !response.access_token.isEmpty else {
            // Log the error response from Google
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("[YouTubePlaylistAuth] Error from Google: \(errorJson)")
            }
            throw YouTubePlaylistAuthError.noTokenReturned
        }
        accessToken = response.access_token
        if let newRefresh = response.refresh_token {
            refreshToken = newRefresh
        }
        if let expiresIn = response.expires_in {
            tokenExpiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        }
        saveToKeychain()
    }

    // MARK: - Keychain Persistence

    private func saveToKeychain() {
        if let token = accessToken {
            KeychainHelper.save(string: token, key: YouTubePlaylistKeychainKey.accessToken, accessibility: kSecAttrAccessibleAfterFirstUnlock)
        }
        if let refresh = refreshToken {
            KeychainHelper.save(string: refresh, key: YouTubePlaylistKeychainKey.refreshToken, accessibility: kSecAttrAccessibleAfterFirstUnlock)
        }
        if let expiry = tokenExpiresAt {
            KeychainHelper.save(string: String(expiry.timeIntervalSince1970), key: YouTubePlaylistKeychainKey.expiresAt, accessibility: kSecAttrAccessibleAfterFirstUnlock)
        }
    }

    private func loadFromKeychain() {
        accessToken = try? KeychainHelper.string(for: YouTubePlaylistKeychainKey.accessToken)
        refreshToken = try? KeychainHelper.string(for: YouTubePlaylistKeychainKey.refreshToken)
        if let expiryString = try? KeychainHelper.string(for: YouTubePlaylistKeychainKey.expiresAt),
           let interval = Double(expiryString) {
            tokenExpiresAt = Date(timeIntervalSince1970: interval)
        }
        isSignedIn = accessToken != nil && !(accessToken?.isEmpty ?? true)
    }

    private func clearKeychain() {
        KeychainHelper.removeKey(YouTubePlaylistKeychainKey.accessToken)
        KeychainHelper.removeKey(YouTubePlaylistKeychainKey.refreshToken)
        KeychainHelper.removeKey(YouTubePlaylistKeychainKey.expiresAt)
    }

    // MARK: - Helpers

    private func urlEncodedBody(_ dict: [String: String]) -> Data? {
        dict
            .map { k, v in "\(k)=\(v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? v)" }
            .joined(separator: "&")
            .data(using: .utf8)
    }

    // MARK: - PKCE

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .prefix(43)
            .description
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return verifier }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest) }
        return Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
