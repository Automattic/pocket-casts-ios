import Foundation

public extension String {
    /// A non-breaking space
    static let nbsp = "\u{00a0}"

    /// Replaces all spaces with non-breaking spaces
    func nonBreakingSpaces() -> String {
        self.replacingOccurrences(of: Constants.space, with: Self.nbsp)
    }

    /// This attempts to prevent widows/orphaned text by applying a non-breaking space between the last words
    /// This also prevents the Pocket Casts from being split up
    func preventWidows() -> String {
        // Prevent Pocket Casts from being separated
        let returnText = self.replacingOccurrences(of: Constants.pocketCasts, with: Constants.pocketCastsNBSP)

        let components = returnText.components(separatedBy: Constants.space)

        guard components.count > 1 else {
            return returnText
        }

        let count = components.count - 1
        var builder: [String] = []

        for (index, word) in components.enumerated() {
            if index > 0 {
                let isLast = index == count
                builder.append(isLast ? .nbsp : Constants.space)
            }
            builder.append(word)
        }

        return builder.joined()
    }

    private enum Constants {
        static let space = " "
        static let pocketCasts = "Pocket Casts"
        static let pocketCastsNBSP = "Pocket" + .nbsp + "Casts"
    }
}
