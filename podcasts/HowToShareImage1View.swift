import SwiftUI

struct HowToShareImage1View: View {
  @EnvironmentObject var theme: Theme

  var body: some View {
    GeometryReader { _ in
      VStack(spacing: -8) {
        // Background Button
        ZStack {
          HStack {
            Spacer()
            HStack(spacing: 46) {
              Text(L10n.howToUploadFirstImageBackgroundButtonText)
                .lineLimit(1)

              Image(systemName: "square.and.arrow.up")
                .font(.system(size: 18).weight(.bold))
                .padding(.top, -3)
            }
            .foregroundStyle(theme.primaryUi01, theme.primaryUi01.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(theme.primaryInteractive01)
            .cornerRadius(8)
            .padding(.leading, 4)

          }
          Color.white
            .opacity(0.7)
            .clipShape(Circle())
            .frame(height: 25)
            .offset(x: 88, y: 19)
            .shadow(color: .black.opacity(0.35), radius: 4.5, y: 2)
        }
        .font(.system(size: 12).weight(.bold))
        // Foreground Menu
        ZStack {
          VStack(spacing: 0) {
            Text(L10n.howToUploadFirstImageForegroundMenuOptionText)
              .lineLimit(1)
              .font(.system(size: 11).weight(.bold))
              .foregroundStyle(theme.primaryField03)
              .padding(.vertical, 8.5)
            Divider()
            HStack {
              Spacer()
              Text("\(L10n.share)...")
                .foregroundStyle(theme.primaryInteractive01)
                .padding(8.5)
                .font(.system(size: 11).weight(.medium))
              Spacer()
            }
            .background(theme.primaryInteractive01.opacity(0.15))
          }
          .background(theme.primaryUi01)
          .cornerRadius(10)
          .shadow(color: .black.opacity(0.18), radius: 5, y: 2)
          .padding(.leading, 8)
          .padding(.trailing, 60)
          // Hover Circle
          Color.white
            .opacity(0.7)
            .clipShape(Circle())
            .frame(height: 25)
            .offset(x: -26, y: 34)
            .shadow(color: .black.opacity(0.35), radius: 4.5, y: 2)
        }
        Spacer()
      }
      .frame(width: 230, height: 120)
    }
  }
}

#Preview {
  HowToShareImage1View()
}
