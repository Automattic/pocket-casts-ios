import SwiftUI

struct ToastView: View {

    let message: String

    var body: some View {
        HStack {
            Text(message)
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
        }
        .glassEffect(.regular)
    }
}
