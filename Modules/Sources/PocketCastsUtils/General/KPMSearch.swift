import Foundation

// An implementation of the Knuth-Morris-Pratt algorithm
public class KMPSearch {
    private var pattern: [Character] = []
    private var lps: [Int] = []
    private var textArray: [String.Element]

    public init(text: String) {
        textArray = Array(text.lowercaseAndDiacriticInsensitive)
    }

    private func computeLPSArray() {
        if lps.isEmpty {
            return
        }

        var length = 0 // length of the previous longest prefix suffix
        lps[0] = 0 // lps[0] is always 0
        var i = 1

        while i < pattern.count {
            if pattern[i] == pattern[length] {
                length += 1
                lps[i] = length
                i += 1
            } else {
                if length != 0 {
                    length = lps[length - 1]
                } else {
                    lps[i] = 0
                    i += 1
                }
            }
        }
    }

    public func search(for pattern: String) -> [Int] {
        if pattern.isEmpty {
            return []
        }

        let pattern = Array(pattern.lowercaseAndDiacriticInsensitive)
        let lps = Array(repeating: 0, count: pattern.count)
        computeLPSArray()

        var result = [Int]()
        var i = 0 // index for textArray
        var j = 0 // index for pattern

        while i < textArray.count {
            if pattern[j] == textArray[i] {
                i += 1
                j += 1
            }

            if j == pattern.count {
                result.append(i - j)
                j = lps[j - 1]
            } else if i < textArray.count && pattern[j] != textArray[i] {
                if j != 0 {
                    j = lps[j - 1]
                } else {
                    i += 1
                }
            }
        }

        return result
    }
}

private extension String {
    var lowercaseAndDiacriticInsensitive: String {
        self
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: nil)
            .replacingOccurrences(of: "ł", with: "l") // diacriticInsensitive doesn't handle this one
    }
}
