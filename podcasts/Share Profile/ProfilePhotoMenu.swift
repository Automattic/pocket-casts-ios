import PhotosUI
import SwiftUI

struct ProfilePhotoMenu: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: ShareProfileViewModel

    var body: some View {
        VStack(spacing: 12) {
            Menu {
                Button {
                    viewModel.showingPhotoPicker = true
                } label: {
                    Label(L10n.shareProfileChoosePhoto, systemImage: "photo.on.rectangle")
                }

                Button {
                    viewModel.showingCamera = true
                } label: {
                    Label(L10n.shareProfileTakePhoto, systemImage: "camera")
                }

                if viewModel.profilePhoto != nil {
                    Divider()

                    Button(role: .destructive) {
                        viewModel.removePhoto()
                    } label: {
                        Label(L10n.shareProfileRemovePhoto, systemImage: "trash")
                    }
                }
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let photo = viewModel.profilePhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 134, height: 134)
                            .clipShape(Circle())
                    } else {
                        ProfileImage(email: viewModel.email)
                            .frame(width: 134, height: 134)
                            .clipShape(Circle())
                    }

                    Image("folder-edit")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(theme.primaryInteractive02)
                        .frame(width: 24, height: 24)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(theme.primaryInteractive01))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(theme.primaryUi01, lineWidth: 3))
                }
            }
        }
        .photosPicker(isPresented: $viewModel.showingPhotoPicker, selection: $viewModel.selectedPhotoItem, matching: .images)
        .fullScreenCover(isPresented: $viewModel.showingCamera) {
            CameraPicker { image in
                viewModel.profilePhoto = image
            }
            .ignoresSafeArea()
        }
    }
}
