public protocol ErrorLogger {
    func log(error: Error, context: [String: String]?)
}
