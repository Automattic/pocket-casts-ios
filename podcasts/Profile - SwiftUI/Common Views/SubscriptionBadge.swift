import SwiftUI
import PocketCastsServer

/// Displays a subscription badge view
/// Example: SubscriptionBadge(type: .plus)
struct SubscriptionBadge: View {
    let tier: SubscriptionTier
    var displayMode: DisplayMode = .black
    var foregroundColor: Color? = nil

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

    private var iconSize: CGFloat {
        switch displayMode {
            case .plain:
                14
            default:
                12
        }
    }

    private var cornerRadius: CGFloat {
        switch displayMode {
            case .plain:
                800
            default:
                20
        }
    }

    private var horizontalPadding: CGFloat {
        switch displayMode {
            case .plain:
                8
            default:
                10
        }
    }

    private var verticalPadding: CGFloat {
        switch displayMode {
            case .plain:
                2
            default:
                6
        }
    }

    @ViewBuilder
    private func render(with model: BadgeModel) -> some View {
        HStack(spacing: 4) {
            Image(model.iconName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(foregroundColor ?? model.iconColor)

            Text(model.label)
                .font(size: fontSize, style: .subheadline, weight: displayMode == .plain ? .medium : .semibold)
                .foregroundColor(foregroundColor ?? .white)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(model.background.cornerRadius(cornerRadius))
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
                case .plain:
                    background = .init(colors: [.black], startPoint: .top, endPoint: .bottom)
                    iconColor = Color(hex: "FFD846")
                }

            case .patron:
                switch displayMode {
                case .black:
                    background = .init(colors: [.init(hex: "6046F5")], startPoint: .top, endPoint: .bottom)
                    iconColor = Color(hex: "E4E0FD")
                case .gradient:
                    background = .init(colors: [.init(hex: "9583F8")], startPoint: .top, endPoint: .bottom)
                    iconColor = .white
                case .plain:
                    background = .init(colors: [.black], startPoint: .top, endPoint: .bottom)
                    iconColor = Color(hex: "#7A64F6")
                }

                iconName = "patron-heart"
                label = L10n.patron

            default:
                return nil
            }
        }
    }

    enum DisplayMode {
        /// Displays the badge using a color background and a white foreground
        case black

        /// Displays the badge using a gradient background for each tier
        case gradient

        /// Display the badge using a solid black background and tier color
        case plain
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

                HStack {
                    SubscriptionBadge(tier: .none, displayMode: .plain) // Won't display
                    SubscriptionBadge(tier: .plus, displayMode: .plain)
                    SubscriptionBadge(tier: .patron, displayMode: .plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}
