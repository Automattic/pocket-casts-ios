import Foundation

extension String {
    private var sourceDescriptor: String {
        if SourceManager.shared.isWatch() {
            return L10n.watch
        }
        return L10n.phone
    }

    var prefixSourceUnicode: String {
        sourceDescriptor.sourceUnicode() + " \(self)"
    }

    func sourceUnicode(isWatch: Bool = SourceManager.shared.isWatch()) -> String {
        let uppercaseSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        guard let firstChar = first,
              let latinFirstCharacter = NSString(string: "\(firstChar)")
              .applyingTransform(.toLatin, reverse: false)?
              .applyingTransform(.stripDiacritics, reverse: false)?
              .capitalized,
              let unicodeScaler = UnicodeScalar(latinFirstCharacter),
              uppercaseSet.contains(unicodeScaler) // Final Check to make sure the character was successfully converted.
        else { return englishSourceUnicode(isWatch) }

        let characterValue = unicodeScaler.value
        let unicodeAValue: UInt32 = UnicodeScalar("A").value
        let offset = characterValue - unicodeAValue

        guard let negativeSpaceCharacter = UnicodeScalar(negativeSpaceAValue(isWatch) + offset) else { return englishSourceUnicode(isWatch) }

        return String(String.UnicodeScalarView([negativeSpaceCharacter]))
    }

    // Fallback for when the string conversions fail.
    private func englishSourceUnicode(_ isWatch: Bool) -> String {
        if isWatch {
            return "🅦"
        }
        return "🅿"
    }

    private func negativeSpaceAValue(_ isWatch: Bool) -> UInt32 {
        if isWatch {
            return UnicodeScalar("\u{1F150}").value // Rounded Unicode character 🅐
        }
        return UnicodeScalar("\u{1F170}").value // Square Unicode character 🅰
    }
}
