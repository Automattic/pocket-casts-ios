import SwiftUI

struct HowToShareActionImageView: View {
    @EnvironmentObject var theme: Theme

    let labelStrings = [L10n.howToUploadShareActionImageSidesText, L10n.howToUploadShareActionImageCenterText, L10n.howToUploadShareActionImageSidesText]

    var body: some View {
        ZStack {
            background()
                .overlay {
                    threeOptions()
                }
                .cornerRadius(12)
                .frame(width: 204)
                .shadow(color: .black.opacity(0.25), radius: 4.5, y: 1.5)
                .padding(.top, 6)
                .padding(.bottom, 25)
            HowToShareMenuImageView.touchCircle(at: .init(x: 0, y: 52.5))
        }
        .frame(width: 220, height: 150)
    }

    @ViewBuilder
    func background() -> some View {
        ZStack {
            theme.primaryUi01
            VStack(spacing: 5) {
                Color.gray
                    .opacity(0.2)
                    .frame(height: 1)
                    .padding(.top, 15)
                theme.primaryInteractive01.opacity(0.15)
                    .cornerRadius(8)
                    .padding(.top, 1)
                    .padding(.horizontal, 41)
                    .padding(.bottom, 5)
            }
        }
    }

    @ViewBuilder
    func threeOptions() -> some View {
        HStack(spacing: 20) {
            ForEach(0..<labelStrings.count, id: \.self) { index in
                VStack(spacing: 10) {
                    (index == 1 ? Color.white : theme.primaryField03.opacity(0.35))
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 43)
                        .cornerRadius(10)
                        .overlay {
                            icon(for: labelStrings[index])
                        }
                    Text(labelStrings[index])
                        .multilineTextAlignment(.center)
                        .font(.system(size: 11).weight(.semibold))
                        .frame(width: 75)
                        .lineLimit(2)
                        .foregroundStyle(index == 1 ? theme.primaryText01 : theme.primaryField03.opacity(0.35))
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.top, 28)

    }

    @ViewBuilder
    func icon(for string: String) -> some View {
        ZStack {
            if string == labelStrings[1] {
                Circle()
                    .fill(Color.black)
                    .opacity(0.65)
                Image("splashlogo")
                    .resizable()
                    .frame(width: 21, height: 21)
            }
        }
        .frame(width: 28, height: 28)
    }
}


#Preview {
    HowToShareActionImageView()
}
