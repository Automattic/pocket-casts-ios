import Foundation
import SwiftUI

struct TipView: View {
    let title: String
    let message: String?
    let sizeChanged: (CGSize)->()
    let onTap: (()->())?

    @EnvironmentObject var theme: Theme

    var body: some View {
        ContentSizeGeometryReader { proxy in
            TipViewStatic(title: title, message: message, onTap: onTap)
        } contentSizeUpdated: { size in
            sizeChanged(size)
        }
    }
}

struct TipViewStatic: View {
    let title: String
    let message: String?
    let showClose: Bool
    let onTap: (()->())?

    init(title: String, message: String?, showClose: Bool = false, onTap: (() -> Void)?) {
        self.title = title
        self.message = message
        self.showClose = showClose
        self.onTap = onTap
    }

    @EnvironmentObject var theme: Theme

    var body: some View {
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
                            .padding(.top, 2)
                    }
                }
                Spacer()
            }
            .padding(16)
            .frame(maxHeight: .infinity)
            .onTapGesture {
                onTap?()
            }
        }.overlay(alignment: .topTrailing) {
            if showClose {
                Button() {
                    onTap?()
                } label: {
                    Image("close")
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryText01)
                        .padding(8)
                }
            }
        }
    }
}

// MARK: - Previews
struct TipView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            TipView(title: L10n.referralsTipTitle(3), message: L10n.referralsTipMessage("2 Months"), sizeChanged: { size in }, onTap: nil).setupDefaultEnvironment()
            Spacer()
        }
    }
}
