extension String {
    public func escapeLike(escapeChar: Character) -> String {
        let escapeCharStr = String(escapeChar)
        return self
            .replacingOccurrences(of: escapeCharStr, with: escapeCharStr + escapeCharStr)
            .replacingOccurrences(of: "%", with: escapeCharStr + "%")
            .replacingOccurrences(of: "_", with: escapeCharStr + "_")
    }
}
