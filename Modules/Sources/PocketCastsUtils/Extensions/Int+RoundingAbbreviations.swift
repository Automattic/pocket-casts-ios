import Foundation

extension Int {

    /// Converts a number to a short abreviated version (1234 = 1.2k, 1234567 1.2M)
    public var abbreviated: String {
        abbreviated(locale: .current)
    }

    func abbreviated(locale: Locale) -> String {
        let number = Double(self)

        switch number {
        case 1_000_000...:
            return "\(scaleDown(value: number, by: 1_000_000, locale: locale))M"

        case 1_000...:
            return "\(scaleDown(value: number, by: 1_000, locale: locale))K"

        default:
            return "\(self)"
        }
    }

    private func scaleDown(value: Double, by amount: Double, locale: Locale) -> String {
        let scaled = round((value / amount) * 10) / 10
        return scaled.formatted(.number.precision(.fractionLength(1)).locale(locale))
    }
}
