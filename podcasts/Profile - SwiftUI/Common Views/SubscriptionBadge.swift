import SwiftUI
import PocketCastsServer

/// Displays a subscription badge view
/// Example: SubscriptionBadge(type: .plus)
///
/// For an extra effect use:
/// SubscriptionBadge(type: .patron, geometryProxy: geometryProxy)
///
struct SubscriptionBadge: View {
    let tier: SubscriptionTier
    var displayMode: DisplayMode = .black

    /// The base of the font the label should use
    var fontSize: Double = 14

    var body: some View {
        let content = BadgeModel(tier: tier, displayMode: displayMode).map { render(with: $0) }

        // Apply an extra effect to the patron badge
        if tier == .patron, displayMode == .black {
            HolographicEffect(mode: .overlay) {
                content
            }
        } else {
            content
        }
    }

    @ViewBuilder
    private func render(with model: BadgeModel) -> some View {
        HStack(spacing: 5) {
            Image(model.iconName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 12, height: 12)
                .foregroundColor(model.iconColor)

            Text(model.label)
                .font(size: fontSize, style: .subheadline, weight: .semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(model.background.cornerRadius(20))
    }

    private struct BadgeModel {
        let iconName: String
        let iconColor: Color
        let label: String
        let background: LinearGradient

        init?(tier: SubscriptionTier, displayMode: DisplayMode) {
            switch tier {
            case .plus:
                iconName = "plusGold"
                label = L10n.pocketCastsPlusShort

                switch displayMode {
                case .black:
                    background = .init(colors: [.black], startPoint: .top, endPoint: .bottom)
                    iconColor = Color(hex: "FFD846")
                case .gradient:
                    background = Color.plusGradient
                    iconColor = .white
                }

            case .patron:
                switch displayMode {
                case .black:
                    background = .init(colors: [.init(hex: "6046F5")], startPoint: .top, endPoint: .bottom)
                    iconColor = Color(hex: "E4E0FD")
                case .gradient:
                    background = Color.patronGradient
                    iconColor = .white
                }

                iconName = "patron-heart"
                label = L10n.patron

            default:
                return nil
            }
        }
    }

    enum DisplayMode {
        /// Displays the badge using a black background and a white foreground
        case black

        /// Displays the badge using a gradient background for each tier
        case gradient
    }
}

// MARK: - Preview
struct SubscriptionBadge_Preview: PreviewProvider {
    static var previews: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading) {
                HStack {
                    SubscriptionBadge(tier: .none) // Won't display
                    SubscriptionBadge(tier: .plus)
                    SubscriptionBadge(tier: .patron)
                }

                HStack {
                    SubscriptionBadge(tier: .none, displayMode: .gradient) // Won't display
                    SubscriptionBadge(tier: .plus, displayMode: .gradient)
                    SubscriptionBadge(tier: .patron, displayMode: .gradient)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}
