import SwiftUI

struct TrimSelectionView: View {
    @Binding var leading: CGFloat
    @Binding var leadingA11yValue: String
    @Binding var trailing: CGFloat
    @Binding var trailingA11yValue: String

    let handleWidth: CGFloat
    let indicatorWidth: CGFloat

    let changed: (CGFloat, TrimHandle.Side) -> Void

    private enum Constants {
        static let borderWidth: CGFloat = 4
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .foregroundColor(Color.clear)
                .border(.tint, width: Constants.borderWidth)
                // Offset and frame are adjusted to hide this rectangle behind the Trim Handles
                .frame(width: (trailing - leading + indicatorWidth) + (Constants.borderWidth * 2))
                .offset(x: leading - Constants.borderWidth)
            TrimHandle(position: $leading, side: .leading, width: handleWidth, onChanged: { changed($0, .leading) })
                .accessibilityLabel(L10n.clipsEndTimeAccessibilityLabel)
                .accessibilityValue(leadingA11yValue)
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        changed(leading - (handleWidth/2) + 2, .leading)
                    case .decrement:
                        changed(leading - (handleWidth/2) - 2, .leading)
                    @unknown default:
                        break
                    }
                }
            TrimHandle(position: $trailing, side: .trailing, width: handleWidth, onChanged: { changed( $0, .trailing) })
                .accessibilityLabel(L10n.clipsEndTimeAccessibilityLabel)
                .accessibilityValue(trailingA11yValue)
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        changed(trailing + (handleWidth/2) + 2, .trailing)
                    case .decrement:
                        changed(trailing + (handleWidth/2) - 2, .trailing)
                    @unknown default:
                        break
                    }
                }
        }
    }
}
