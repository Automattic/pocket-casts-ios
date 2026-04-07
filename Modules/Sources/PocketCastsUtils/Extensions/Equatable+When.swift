import Foundation

public extension Equatable {
    /// `.when` allows you to perform the `action` closure when the object and `value` are equal.
    ///
    /// While this essentially a wrapper around an is equal check this helps reduce some boilerplate when you want to
    /// both return the value and perform an action if that value is equal to something.
    ///
    /// Examples:
    ///
    ///     // Before:
    ///     func doSomething() -> Bool {
    ///         let success = database.addTheThing()
    ///
    ///         if success { sendSomething() }
    ///
    ///         return success
    ///     }
    ///
    ///     // After:
    ///     func doSomething() -> Bool {
    ///         database.addTheThing().when(true) {
    ///             sendSomething()
    ///         }
    ///     }
    ///
    ///
    @discardableResult
    func when(_ value: Self, _ action: () throws -> Void) rethrows -> Self {
        if self == value {
            try action()
        }

        return self
    }
}
