import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct ShareProfileCardView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: ShareProfileViewModel

    var body: some View {
        ZStack {
            Color(UIColor(hex: "#F43E37")).ignoresSafeArea()

            VStack(spacing: 0) {
                if let photo = viewModel.profilePhoto {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 240, height: 240)
                        .clipShape(Circle())
                }

                Text(viewModel.displayName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)

                Image("horizontal-logo-dark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 18)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

struct ShareProfileCardView_Previews: PreviewProvider {
    static var previews: some View {
        ShareProfileCardView(viewModel: ShareProfileViewModel())
            .frame(width: 340, height: 400)
            .previewLayout(.sizeThatFits)
            .setupDefaultEnvironment()
    }
}
