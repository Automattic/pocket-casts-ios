import Combine
import Foundation
import SwiftUI

struct ActivityDialog: ViewModifier {
    @EnvironmentObject var theme: Theme

    @Binding var isShowing: Bool
    let message: String

    public func body(content: Content) -> some View {
        ZStack {
            content

            if isShowing {
                Rectangle()
                    .foregroundColor(.black.opacity(0.2))
                    .ignoresSafeArea()
                VStack(alignment: .center, spacing: 10) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ThemeColor.primaryIcon01(for: theme.activeTheme).color))
                    Text(message)
                        .textStyle(PrimaryText())
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(ThemeColor.primaryUi01(for: theme.activeTheme).color)
                )
            }
        }
    }
}

public extension View {
    func activityIndicator(isShowing: Binding<Bool>, message: String) -> some View {
        modifier(ActivityDialog(isShowing: isShowing, message: message))
    }
}
