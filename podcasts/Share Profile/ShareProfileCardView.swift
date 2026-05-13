import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct ShareProfileCardView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: ShareProfileViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            if let photo = viewModel.profilePhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .init(x: 0.5, y: 0.3),
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                Spacer()

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.displayName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("pocketcasts.com")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Image("horizontal-logo-dark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

struct ShareProfileCardView_Previews: PreviewProvider {
    static var previews: some View {
        ShareProfileCardView(viewModel: ShareProfileViewModel())
            .frame(width: 390, height: 520)
            .previewLayout(.sizeThatFits)
            .setupDefaultEnvironment()
    }
}
