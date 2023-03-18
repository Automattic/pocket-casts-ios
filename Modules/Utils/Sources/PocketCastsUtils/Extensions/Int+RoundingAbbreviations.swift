import Foundation

extension Int {

    /// Converts a number to a short abreviated version (1234 = 1.2k, 1234567 1.2M)
    public var abbreviated: String {
        let number = Double(self)

        switch number {
        case 1_000_000...:
            return "\(scaleDown(value: number, by: 1_000_000))M"

        case 1_000...:
            return "\(scaleDown(value: number, by: 1_000))K"

        default:
            return "\(self)"
        }
    }

    private func scaleDown(value: Double, by amount: Double) -> Double {
        round((value / amount) * 10) / 10
    }
}
