import SwiftUI

struct HowToShareImage2View: View {
  @EnvironmentObject var theme: Theme

  let labelStrings = [L10n.howToUploadSecondImageSidesText, L10n.howToUploadSecondImageCenterText, L10n.howToUploadSecondImageSidesText]

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

  var body: some View {
    GeometryReader { _ in
      ZStack {
        // background
        theme.primaryUi01
          .overlay {
            ZStack {
              // center selection square
              VStack(spacing: 5) {
                Color.gray
                  .opacity(0.2)
                  .frame(height: 1)
                  .padding(.top, 15)
                HStack {
                  theme.primaryInteractive01.opacity(0.15)
                    .cornerRadius(8)
                    .padding(.top, 1)
                    .padding(.horizontal, 82)
                    .padding(.bottom, 5)
                }
              }
              // icons and labels
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
            .clipped()
          }
          .clipped()
          .cornerRadius(12)
          .frame(width: 204)
          .shadow(color: .black.opacity(0.25), radius: 4.5, y: 1.5)
          .padding(.top, 6)
          .padding(.bottom, 25)
        // touch circle
        Color.white
          .opacity(0.7)
          .clipShape(Circle())
          .frame(height: 25)
          .offset(x: 0, y: 52.5)
          .shadow(color: .black.opacity(0.35), radius: 4.5, y: 2)
      }
      .frame(width: 220, height: 150)
    }
  }
}


#Preview {
  HowToShareImage2View()
}
