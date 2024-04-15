extension Date {
    /// A default date to use when syncing with the server.
    /// The server defaults to the epoch date and if we don't set to a date _slightly_ after that, it will not store the new setting.
    static var syncDefaultDate: Date {
        Date(timeIntervalSince1970: 1)
    }
}
