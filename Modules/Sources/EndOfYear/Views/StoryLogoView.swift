import SwiftUI

public struct StoryLogoView: View {
    public var body: some View {
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

    public init() {}

    public enum Constants {
        public static let paddingBottom = 49.0
    }
}
