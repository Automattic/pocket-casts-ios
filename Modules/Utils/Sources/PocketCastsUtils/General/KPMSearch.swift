import Foundation

// An implementation of the Knuth-Morris-Pratt algorithm
public class KMPSearch {
    private var pattern: [Character]
    private var lps: [Int]

    public init(pattern: String) {
        self.pattern = Array(pattern.lowercased())
        self.lps = Array(repeating: 0, count: pattern.count)
        computeLPSArray()
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

    public func search(in text: String) -> [Int] {
        if pattern.isEmpty {
            return []
        }

        let textArray = Array(text.lowercased())
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
