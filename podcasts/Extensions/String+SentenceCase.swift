import Foundation

extension String {

    var sentenceCased: String {
        var components = self.localizedLowercase.components(separatedBy: " ")
        if let first = components.first {
            components[0] = first.localizedCapitalized
        }
        let result = components.joined(separator: " ")
        return result
    }
}
