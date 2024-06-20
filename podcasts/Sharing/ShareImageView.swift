import SwiftUI
import Kingfisher

struct ShareImageInfo {
    let name: String
    let title: String
    let description: String
    let artwork: URL
    let gradient: Gradient
}

enum ShareImageStyle: CaseIterable {
    case large
    case medium
    case small

    var tabString: String {
        switch self {
        case .large:
            return "large"
        case .medium:
            return "medium"
        case .small:
            return "small"
        }
    }
}

struct ShareImageView: View {

    let info: ShareImageInfo
    let style: ShareImageStyle

    var body: some View {
        ZStack {
            LinearGradient(gradient: info.gradient, startPoint: .top, endPoint: .bottom)
            Color.black.opacity(0.2)
            switch style {
            case .large:
                VStack(spacing: 32) {
                    image()
                        .frame(width: 200, height: 200)
                    text()
                    PocketCastsLogoPill()
                }
                .padding(24)
                .frame(width: 292, height: 438)
            case .medium:
                VStack(spacing: 24) {
                    image()
                        .frame(width: 120, height: 120)
                    text()
                        .frame(alignment: .leading)
                }
                .padding(24)
                .frame(width: 292, height: 293)
            case .small:
                HStack(spacing: 18) {
                    image()
                        .frame(width: 120, height: 120)
                    text(alignment: .leading, textAlignment: .leading, lineLimit: 3)
                }
                .padding(24)
                .frame(width: 324, height: 169)
            }
        }
        .fixedSize()
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder func image() -> some View {
        KFImage(info.artwork)
            .resizable()
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder func text(alignment: HorizontalAlignment = .center, textAlignment: TextAlignment = .center, lineLimit: Int = 2) -> some View {
        VStack(alignment: alignment, spacing: 6) {
            Text(info.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))
            Text(info.title)
                .font(Font.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(lineLimit)
            Text(info.description)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))
        }
        .multilineTextAlignment(textAlignment)
    }
}

let previewInfo = ShareImageInfo(name: "This American Life", title: "Dylan Field, Figma Co-founder, Talks Design, Economy, and life after failed Adobe acquisitions", description: Date().formatted(), artwork: URL(string: "https://static.pocketcasts.com/discover/images/280/3782b780-0bc5-012e-fb02-00163e1b201c.jpg")!, gradient: Gradient(colors: [Color.red, Color(hex: "620603")]))

#Preview("large") {
    ShareImageView(info: previewInfo, style: .large)
}

#Preview("medium") {
    ShareImageView(info: previewInfo, style: .medium)
}

#Preview("small") {
    ShareImageView(info: previewInfo, style: .small)
}
