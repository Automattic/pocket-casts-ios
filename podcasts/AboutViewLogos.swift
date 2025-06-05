import SwiftUI

enum AboutLogo: CaseIterable {
    case jetpack, dayone, pocketcasts, simplenote, woo, tumblr

    var logoName: String {
        switch self {
        case .jetpack:
            return "family_jetpack_logo"
        case .dayone:
            return "family_dayone_logo"
        case .pocketcasts:
            return "family_pc_logo"
        case .simplenote:
            return "family_simplenote_logo"
        case .woo:
            return "family_woo_logo"
        case .tumblr:
            return "family_tumblr_logo"
        }
    }

    func logoTint(onDark: Bool) -> Color? {
        if self == .tumblr {
            return onDark ? Color.white : nil
        }

        return nil
    }

    var color: Color {
        let uiColor: UIColor
        switch self {
        case .jetpack:
            uiColor = UIColor(hex: "#00BF2A")
        case .dayone:
            uiColor = UIColor(hex: "#45BFFF")
        case .pocketcasts:
            uiColor = UIColor(hex: "#F53D38")
        case .simplenote:
            uiColor = UIColor(hex: "#3361CC")
        case .woo:
            uiColor = UIColor(hex: "#B899FF")
        case .tumblr:
            uiColor = UIColor(hex: "#001933")
        }

        let alphaColor = uiColor.withAlphaComponent(0.16)

        return Color(alphaColor)
    }

    var description: String {
        switch self {
        case .jetpack:
            return "Jetpack"
        case .dayone:
            return "Day One"
        case .pocketcasts:
            return "Pocket Casts"
        case .simplenote:
            return "Simple Note"
        case .woo:
            return "Woo Commerce"
        case .tumblr:
            return "Tumblr"
        }
    }

    func randomRotation(maxDegrees: Double) -> Angle {
        if self == .pocketcasts { return Angle(degrees: 0) }

        return Angle(degrees: Double.random(in: -maxDegrees ..< maxDegrees))
    }
}
