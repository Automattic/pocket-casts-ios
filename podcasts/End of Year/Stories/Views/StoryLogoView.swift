import SwiftUI

struct StoryLogoView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image("logo")
                    .padding(.bottom, Constants.paddingBottom)
                Spacer()
            }
        }
    }

    enum Constants {
        static let paddingBottom = 29.0
    }
}
