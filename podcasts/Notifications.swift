import Foundation

extension NSNotification.Name {
    /// When a user has signed in, signed out, or been signed in during account creation
    static let userLoginDidChange = NSNotification.Name("User.LoginChanged")
}
