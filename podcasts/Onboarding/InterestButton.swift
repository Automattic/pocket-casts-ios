import SwiftUI
import Kingfisher

struct InterestButton: View {

    @EnvironmentObject var theme: Theme

    let name: String
    let icon: String?
    let isSelected: Bool
    let style: Style
    let action: (() -> Void)?

    @State private var isAnimatingSelection = false

    init(name: String, icon: String?, isSelected: Bool = false, style: Style = .red, action: (() -> Void)? = nil) {
        self.name = name
        self.icon = icon
        self.isSelected = isSelected
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: {
            doAnimationAndAction()
        }) {
            HStack {
                if let icon = icon, let url = URL(string: icon) {
                    ZStack {
                        if isSelected {
                            KFImage(url)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: Constants.iconSize, height: Constants.iconSize)
                                .foregroundColor(style.selectedForegroundColor)
                        } else {
                            self.style.gradient.mask(
                                KFImage(url)
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                            )
                        }
                    }.frame(width: Constants.iconSize, height: Constants.iconSize)
                }
                Text(name)
                    .font(.title3.weight(.medium))
                    .foregroundColor(isSelected ? style.selectedForegroundColor : theme.secondaryText02)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, Constants.Padding.horizontal)
        .padding(.vertical, Constants.Padding.vertical)
        .cornerRadius(Constants.cornerRadius)
        .background {
            if isSelected {
                RoundedRectangle(cornerSize: CGSize(width: Constants.cornerRadius, height: Constants.cornerRadius))
                    .fill(self.style.gradient)
            } else {
                RoundedRectangle(cornerSize: CGSize(width: Constants.cornerRadius, height: Constants.cornerRadius))
                    .fill(theme.primaryUi01)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .inset(by: 1)
                .stroke(isSelected ? .clear : theme.primaryUi05, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .scaleEffect(isAnimatingSelection ? 1.2 : 1)
        .rotationEffect(Angle(degrees: isAnimatingSelection ? -3 : 0))
    }

    private func doAnimationAndAction() {
        if isSelected {
            action?()
        } else {
            withAnimation(.easeOut(duration: 0.1)) {
                isAnimatingSelection.toggle()
            }
            withAnimation(.interpolatingSpring(stiffness: 600, damping: 15).delay(0.1)) {
                action?()
                isAnimatingSelection.toggle()
            }
        }
    }

    enum Style: Int, CaseIterable {
        case red
        case yellow
        case purple
        case blue
        case green

        var gradient: LinearGradient {
            switch self {
                case .red:
                    return LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.96, green: 0.22, blue: 0.41), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.98, green: 0.32, blue: 0.27), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0, y: 0),
                        endPoint: UnitPoint(x: 1, y: 1)
                    )
                case .yellow:
                    return LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 1, green: 0.84, blue: 0.27), location: 0.00),
                            Gradient.Stop(color: Color(red: 1, green: 0.71, blue: 0.15), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.09, y: 0),
                        endPoint: UnitPoint(x: 0.95, y: 0.61)
                    )
                case .purple:
                    return LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.38, green: 0.27, blue: 0.91), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.91, green: 0.29, blue: 0.54), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 1.06, y: 0.64),
                        endPoint: UnitPoint(x: -0.08, y: 0.5)
                    )
                case .blue:
                    return LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.01, green: 0.66, blue: 0.96), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.31, green: 0.82, blue: 0.95), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.05, y: 0.08),
                        endPoint: UnitPoint(x: 0.95, y: 0.92)
                    )
                case .green:
                    return LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.47, green: 0.84, blue: 0.29), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.61, green: 0.89, blue: 0.37), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.13, y: 0.01),
                        endPoint: UnitPoint(x: 0.89, y: 1.01)
                    )
            }
        }

        var tintColor: Color {
            switch self {
                case .red:
                    return Color(hex: "#F43769")
                case .yellow:
                    return Color(hex: "#FED745")
                case .purple:
                    return Color(hex: "#6046E9")
                case .blue:
                    return Color(hex: "#03A9F4")
                case .green:
                    return Color(hex: "#78D549")
            }
        }

        var selectedForegroundColor: Color {
            switch self {
                case .yellow:
                    return Color(hex: "#B25900")
                case .green:
                    return Color(hex: "#3B862D")
                default:
                    return .white
            }
        }
    }

    private enum Constants {
        enum Padding {
            static let horizontal: CGFloat = 16
            static let vertical: CGFloat = 12
        }

        static let cornerRadius = CGFloat(102)

        static let iconSize = CGFloat(24)
    }
}

// MARK: Previews

#Preview("normal") {
    InterestButton(name: "Arts", icon: "", isSelected: false, style: .red)
        .previewWithAllThemes()
}
