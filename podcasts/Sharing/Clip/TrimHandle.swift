import SwiftUI

struct TrimHandle: View {
    enum Side {
        case leading
        case trailing
    }

    @Binding var position: CGFloat
    let side: Side
    let onChanged: (CGFloat) -> Void

    private enum Constants {
        static let innerLineColor = Color(hex: "281313").opacity(0.2)
        static let innerLineWidth = 1.5
        static let width: CGFloat = 17
        static let cornerRadius: CGFloat = 8
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.tint)
                .modify { view in
                    if #available(iOS 16, *) {
                        view.clipShape(.rect(topLeadingRadius: edgeRadius.leading,
                                             bottomLeadingRadius: edgeRadius.leading,
                                             bottomTrailingRadius: edgeRadius.trailing,
                                             topTrailingRadius: edgeRadius.trailing))
                    } else {
                        view.clipShape(PCUnevenRoundedRectangle(topLeadingRadius: edgeRadius.leading,
                                                                bottomLeadingRadius: edgeRadius.leading,
                                                                bottomTrailingRadius: edgeRadius.trailing,
                                                                topTrailingRadius: edgeRadius.trailing))
                    }
                }
            handleLine
        }
        .frame(width: Constants.width)
        .offset(x: offset)
        .onTapGesture {}
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    onChanged(value.location.x)
                }
        )
    }

    @ViewBuilder private var handleLine: some View {
        RoundedRectangle(cornerRadius: Constants.cornerRadius)
            .fill(Constants.innerLineColor)
            .frame(width: Constants.innerLineWidth)
            .padding(.vertical, Constants.width)
    }

    var offset: CGFloat {
        switch side {
        case .leading:
            position - Constants.width
        case .trailing:
            position
        }
    }

    var edgeRadius: (leading: CGFloat, trailing: CGFloat) {
        switch side {
        case .leading:
            (Constants.cornerRadius, 0)
        case .trailing:
            (0, Constants.cornerRadius)
        }
    }
}
