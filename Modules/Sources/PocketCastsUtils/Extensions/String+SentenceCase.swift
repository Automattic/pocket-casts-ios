import Foundation

extension String {

    public var sentenceCased: String {
        sentenceCased(locale: .current)
    }

    func sentenceCased(locale: Locale) -> String {
        guard locale.language.languageCode != .german else {
            return self
        }
        var components = self.localizedLowercase.components(separatedBy: " ")
        if let first = components.first {
            components[0] = first.localizedCapitalized
        }
        let result = components.joined(separator: " ")
        return result
    }
}
