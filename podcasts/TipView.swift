import Foundation
import SwiftUI

struct TipView: View {
    let title: String
    let message: String?
    let sizeChanged: (CGSize)->()
    @EnvironmentObject var theme: Theme

    var body: some View {
        ContentSizeGeometryReader { proxy in
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(size: 15, style: .body, weight: .bold)
                            .foregroundColor(theme.primaryText01)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        if let message {
                            Text(message)
                                .font(size: 14, style: .body, weight: .regular)
                                .foregroundColor(theme.primaryText02)
                                .lineLimit(4)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer()
                }
                .padding(16)
                .frame(maxHeight: .infinity)
            }
        } contentSizeUpdated: { size in
            sizeChanged(size)
        }
    }
}

// MARK: - Previews
struct TipView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            TipView(title: L10n.referralsTipTitle(3), message: L10n.referralsTipMessage("2 Months"), sizeChanged: { size in }).setupDefaultEnvironment()
            Spacer()
        }
    }
}
