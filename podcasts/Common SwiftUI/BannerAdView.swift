import SwiftUI

class BannerAdModel: ObservableObject {
    let adText: String
    let imageURL: URL
    let adLabel: String
    let titleLabel: String
    let onLinkTap: (() -> Void)?

    init(adText: String, imageURL: URL, linkTitle: String, titleLabel: String = L10n.bannerAdsInfoLabel, onLinkTap: (() -> Void)? = nil) {
        self.adText = adText
        self.imageURL = imageURL
        self.adLabel = titleLabel
        self.titleLabel = linkTitle
        self.onLinkTap = onLinkTap
    }
}

struct BannerAdView: View {
    struct Colors {
        let background: Color
        let adText: Color
        let titleLabel: Color
        let adLabelBackground: Color
        let adLabel: Color
        let icon: Color
        let border: Color?

        static func podcastList(_ theme: Theme) -> Self {
            return Self(
                background: theme.primaryUi06,
                adText: theme.primaryText01,
                titleLabel: theme.primaryInteractive01,
                adLabelBackground: theme.primaryInteractive01,
                adLabel: theme.primaryUi02Active,
                icon: theme.primaryIcon02,
                border: theme.primaryUi05
            )
        }
    }

    @ObservedObject var model: BannerAdModel
    private let colors: Colors
    @EnvironmentObject var theme: Theme
    @Environment(\.sizeCategory) private var sizeCategory

    init(model: BannerAdModel, colors: Colors) {
        self.model = model
        self.colors = colors
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            creative()
            VStack(alignment: .leading, spacing: 8) {
                Text(model.adText)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(colors.adText)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 4) {
                    Text(model.adLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(colors.adLabel)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(colors.adLabelBackground)
                        .cornerRadius(4)
                    Button(action: { model.onLinkTap?() }) {
                        Text(model.titleLabel)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(colors.titleLabel)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            VStack {
                Button(action: {
                    //TODO: Add Ad reporting action in future PR
                }, label: {
                    Image(systemName: "ellipsis")
                        .bold()
                        .foregroundStyle(colors.icon)
                })
                .padding(10)
                Spacer()
            }
        }
        .padding(8)
        .background(colors.background)
        .modify {
            if let border = colors.border {
                $0.overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(border, lineWidth: 1)
                )
            }
        }
        .cornerRadius(8)
        .padding(.vertical, 10)
    }

    @ViewBuilder func creative() -> some View {
        AsyncImage(url: model.imageURL) { phase in
            switch phase {
            case .empty, .failure:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .cornerRadius(4)
            @unknown default:
                ProgressView()
                    .onAppear {
                        assertionFailure("Unexpected AsyncImage phase: \(phase)")
                    }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(width: 86, height: 86)
    }
}

#Preview("Light - Podcast List Theme") {
    BannerAdView(
        model: .init(
            adText: "Listen to your favorite books while supporting your local indie bookstore",
            imageURL: URL(string: "https://static.pocketcasts.com/discover/images/420/9349e8d0-a87f-013a-d8af-0acc26574db2.jpg")!,
            linkTitle: "Libro.fm"
        ),
        colors: .podcastList(Theme(previewTheme: .light))
    )
    .environmentObject(Theme(previewTheme: .light))
    .padding(16)
    .frame(maxWidth: 400)
}

#Preview("Dark - Podcast List Theme") {
    BannerAdView(
        model: .init(
            adText: "Listen to your favorite books while supporting your local indie bookstore",
            imageURL: URL(string: "https://static.pocketcasts.com/discover/images/420/9349e8d0-a87f-013a-d8af-0acc26574db2.jpg")!,
            linkTitle: "Libro.fm"
        ),
        colors: .podcastList(Theme(previewTheme: .light))
    )
    .environmentObject(Theme(previewTheme: .dark))
    .padding(16)
    .frame(maxWidth: 400)
}
