import Foundation

extension String {
    /// Converts a camel cased word (ohHelloThere) into snake case (oh_hello_there)
    /// - Returns: A snack cased string
    func toSnakeCaseFromCamelCase() -> String {
        // Support acronyms, and prevent early snake casing them.
        // helloJSONWorld -> hello_json_world
        let acronymPattern = "([A-Z0-9]+)([A-Z0-9][a-z]|[0-9])"

        // Match the last lowercase, and the first uppercase then put a _ between them
        // helloWorld -> hello_world
        let normalPattern = "([a-z0-9])([A-Z])"
        return snakeCasePattern(acronymPattern)?.snakeCasePattern(normalPattern)?.lowercased() ?? lowercased()
    }

    /// - Parameter pattern: <#pattern description#>
    /// - Returns: <#description#>
    private func snakeCasePattern(_ pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }
}
