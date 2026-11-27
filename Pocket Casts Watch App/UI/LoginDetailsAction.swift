public enum LoginDetailsAction: Equatable {
    case signOut
    case logIn
    case switchAccount
    case recheckSubscription

    /// What the watch should do with the login details the phone sends after flagging `loginChanged`.
    /// A Plus purchase on the phone also flags `loginChanged` without changing the account, so a watch
    /// that is already signed in re-checks its subscription instead of keeping a stale status for up to 24 hours.
    /// If the phone is now signed in to a different account, the watch has to sign in again: its token,
    /// subscription status and data still belong to the previous account.
    public static func makeAction(isLoggedIn: Bool, watchUsername: String, phoneUsername: String) -> LoginDetailsAction {
        guard isLoggedIn else { return .logIn }
        guard !phoneUsername.isEmpty else { return .signOut }

        return watchUsername.caseInsensitiveCompare(phoneUsername) == .orderedSame ? .recheckSubscription : .switchAccount
    }
}
