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
    case audio

    var tabString: String {
        switch self {
        case .large:
            return "large"
        case .medium:
            return "medium"
        case .small:
            return "small"
        case .audio:
            return "audio"
        }
    }

    var videoSize: CGSize {
        switch self {
        case .large:
            CGSize(width: 292, height: 438)
        case .medium:
            CGSize(width: 292, height: 293)
        case .small:
            CGSize(width: 324, height: 169)
        case .audio:
            CGSize(width: 100, height: 100)
        }
    }
}

struct ShareImageView: View {

    let info: ShareImageInfo
    let style: ShareImageStyle

    @Binding var angle: Double

    var body: some View {
        ZStack {
            switch style {
            case .large:
                background()
                VStack(spacing: 32) {
                    image()
                        .aspectRatio(1, contentMode: .fit)
                    text()
                    PocketCastsLogoPill()
                }
                .padding(24)
                .aspectRatio(0.66, contentMode: .fit)
            case .medium:
                background()
                VStack(spacing: 24) {
                    image()
                        .aspectRatio(1, contentMode: .fit)
                    text()
                        .frame(alignment: .leading)
                }
                .padding(24)
                .aspectRatio(0.99, contentMode: .fit)
            case .small:
                background()
                HStack(spacing: 18) {
                    image()
                        .aspectRatio(1, contentMode: .fit)
                    text(alignment: .leading, textAlignment: .leading, lineLimit: 3)
                }
                .padding(24)
                .aspectRatio(1.97, contentMode: .fit)
            case .audio:
                Image("music")
            }
        }
        .frame(width: style.videoSize.width, height: style.videoSize.height)
        .fixedSize()
    }

    @ViewBuilder func background() -> some View {
        LinearGradient(gradient: info.gradient, startPoint: .top, endPoint: .bottom)
        let rotationFactor = sin(Angle(degrees: angle).radians)
        KidneyShape()
            .fill(info.gradient.stops.first?.color ?? .black)
            .blur(radius: 50)
            .opacity(0.15 + 0.5 * abs(rotationFactor))
            .offset(x: -50, y: 0)
            .rotationEffect(.degrees(180 * rotationFactor))
        KidneyShape()
            .fill(.white)
            .blur(radius: 50)
            .offset(x: 50, y: 0)
            .opacity(0.15 + 0.5 * abs(rotationFactor))
            .rotationEffect(.degrees(-180 * rotationFactor))
            .blendMode(.softLight)
        Color.black.opacity(0.2)
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

struct KidneyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.minY),
            control2: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control1: CGPoint(x: rect.maxX, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.maxY)
        )

        // Indentation
        let indentWidth = rect.width * 0.2
        let indentHeight = rect.height * 0.3
        path.move(to: CGPoint(x: rect.midX - indentWidth, y: rect.minY + rect.height * 0.3))
        path.addCurve(
            to: CGPoint(x: rect.midX + indentWidth, y: rect.minY + rect.height * 0.3),
            control1: CGPoint(x: rect.midX - indentWidth / 2, y: rect.minY + indentHeight),
            control2: CGPoint(x: rect.midX + indentWidth / 2, y: rect.minY + indentHeight)
        )

        return path
    }
}

@available(iOS 16.0, *)
extension ShareImageView: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation<Self>(exportedContentType: .png) { view in
            try await view.snapshot().pngData().throwOnNil()
        }
    }
}

extension View {
    func itemProvider() -> NSItemProvider {
        let itemProvider = NSItemProvider()
        if #available(iOS 16.0, *) {
            itemProvider.registerDataRepresentation(for: .png) { completion in
                Task.detached {
                    await completion(snapshot().pngData(), nil)
                }
                return nil
            }
        } else {
            itemProvider.registerDataRepresentation(forTypeIdentifier: UTType.png.identifier, visibility: .all) { completion in
                Task.detached {
                    await completion(snapshot().pngData(), nil)
                }
                return nil
            }
        }
        return itemProvider
    }
}
let previewInfo = ShareImageInfo(name: "This American Life", title: "Dylan Field, Figma Co-founder, Talks Design, Economy, and life after failed Adobe acquisitions", description: Date().formatted(), artwork: URL(string: "https://static.pocketcasts.com/discover/images/280/3782b780-0bc5-012e-fb02-00163e1b201c.jpg")!, gradient: Gradient(colors: [Color.red, Color(hex: "620603")]))

#Preview("large") {
    ShareImageView(info: previewInfo, style: .large, angle: .constant(0))
}

#Preview("medium") {
    ShareImageView(info: previewInfo, style: .medium, angle: .constant(0))
}

#Preview("small") {
    ShareImageView(info: previewInfo, style: .small, angle: .constant(0))
}
