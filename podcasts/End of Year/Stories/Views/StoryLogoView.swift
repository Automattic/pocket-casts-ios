import SwiftUI

struct StoryLogoView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image("logo_white")
                    .padding(.bottom, Constants.paddingBottom)
                Spacer()
            }
        }
    }

    private enum Constants {
        static let paddingBottom = 24.0
    }
}
