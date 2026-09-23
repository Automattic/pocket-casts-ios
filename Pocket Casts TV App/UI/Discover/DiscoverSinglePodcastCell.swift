import SwiftUI
import PocketCastsUtils
import PocketCastsServer

struct DiscoverSinglePodcastCell: View {

    let model: DiscoverPodcast
    let sponsored: Bool

    @Environment(\.isFocused) private var isFocused: Bool

    enum Layout {
        static let imageSize = CGFloat(272)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let uuid = model.uuid {
            PodcastImage(uuid: uuid, size: .page)
        }
    }

    var body: some View {
        HStack(spacing: 24) {
            thumbnail
                .frame(width: Layout.imageSize, height: Layout.imageSize)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    if sponsored {
                        Text(L10n.discoverSponsored.sentenceCased)
                            .font(.body)
                            .foregroundColor(isFocused ? .pcTextPrimaryActive : .pcTextPrimary)
                        Text("·")
                            .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                    }
                    if let author = model.author {
                        Text(author)
                            .font(.body)
                            .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                    }
                    Spacer()
                }
                Text(model.title ?? "")
                    .font(.title2)
                    .foregroundColor(isFocused ? .pcTextPrimaryActive : .pcTextPrimary)
                    .lineLimit(2)
                if let description = model.shortDescription {
                    Text(description)
                        .font(.body)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer()
        }
        .padding(32)
        .background(isFocused ? Color.pcBackgroundActive : Color.pcBackgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
