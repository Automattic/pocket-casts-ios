import SwiftUI

struct HowToShareMenuImageView: View {
    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(spacing: -8) {
            topTrailingBackgroundButton()
            bottomLeadingForegroundMenu()
        }
        .frame(width: 230, height: 120)
    }

    @ViewBuilder
    func topTrailingBackgroundButton() -> some View {
        ZStack {
            HStack {
                Spacer()
                HStack(spacing: 46) {
                    Text(L10n.howToUploadShareMenuImageBackgroundButtonText)
                        .lineLimit(1)
                        .font(.system(size: 12).weight(.bold))

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
            Self.touchCircle(at: .init(x: 88, y: 19))
        }
    }

    @ViewBuilder
    func bottomLeadingForegroundMenu() -> some View {
        ZStack {
            VStack(spacing: 0) {
                Text(L10n.howToUploadShareMenuImageForegroundMenuOptionText)
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
            Self.touchCircle(at: .init(x: -26, y: 34))
        }
    }

    @ViewBuilder
    static func touchCircle(at offset: CGPoint) -> some View {
        Color.white
            .opacity(0.7)
            .clipShape(Circle())
            .frame(height: 25)
            .shadow(color: .black.opacity(0.35), radius: 4.5, y: 2)
            .offset(x: offset.x, y: offset.y)
    }
}

#Preview {
    HowToShareMenuImageView()
}
