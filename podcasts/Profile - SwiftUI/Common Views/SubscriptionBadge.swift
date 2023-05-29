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

    var body: some View {
        let content = BadgeModel(tier: tier).map { render(with: $0) }

        // Apply an extra effect to the patron badge
        if tier == .patron {
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
                .font(size: 14, style: .subheadline, weight: .semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(model.backgroundColor.cornerRadius(20))
    }

    private struct BadgeModel {
        let iconName: String
        let iconColor: Color
        let label: String
        let backgroundColor: Color

        init?(tier: SubscriptionTier) {
            switch tier {
            case .plus:
                backgroundColor = .black
                iconColor = Color(hex: "FFD846")
                iconName = "plusGold"
                label = L10n.pocketCastsPlusShort

            case .patron:
                backgroundColor = Color(hex: "6046F5")
                iconColor = Color(hex: "E4E0FD")
                iconName = "patron-heart"
                label = L10n.patron

            default:
                return nil
            }
        }
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
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}
