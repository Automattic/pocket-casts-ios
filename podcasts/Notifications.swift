import Foundation

extension NSNotification.Name {
    /// When a user has signed in, signed out, or been signed in during account creation
    static let userLoginDidChange = NSNotification.Name("User.LoginChanged")

    /// When the requirement for having an account or not to see End Of Year Stats changes
    static let eoyRegistrationNotRequired = NSNotification.Name("EOY.RegistrationNotRequired")
}
