import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import Kingfisher

struct DiscoverCategoryCell: View {
    @State var model: DiscoverCategoryModel

    @Environment(\.isFocused) var isFocused: Bool

    enum Layout {
        static let imageSize = CGFloat(156)
        static let rotationEffect = CGFloat(15)
        static let cardHeight = CGFloat(258)
        static let iconSize = CGFloat(48)
    }

    init(category: DiscoverCategory) {
        _model = State(wrappedValue: DiscoverCategoryModel(category: category))
    }

    var body: some View {
        ZStack(alignment: .center) {
            VStack(alignment: .center) {
                Spacer()
                if let url = model.icon {
                    KFImage(url)
                        .renderingMode(.template)
                        .resizable()
                        .tint(isFocused ? Color.pcTextPrimary : Color.pcTextSecondary)
                        .frame(width: Layout.iconSize, height: Layout.iconSize)
                }
                Text(model.name)
                    .font(.headline)
                    .foregroundColor(isFocused ? Color.pcTextPrimary : Color.pcTextSecondary)
                Spacer()
                HStack(alignment: .bottom) {
                    Spacer()
                }
            }
            .padding(.vertical, 24)
            ZStack {
                if model.state == .ready,
                   let firstPodcast = model.coverPodcastsUuids.first,
                   let lastPodcast = model.coverPodcastsUuids.last {
                    HStack {
                        PodcastImage(uuid: firstPodcast, size: .page)
                            .frame(width: Layout.imageSize, height: Layout.imageSize)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: .pcShadowLight, radius: 37.5, x: 0, y: 0)
                            .offset(x: isFocused ? -Layout.imageSize : 0)
                            .scaleEffect(isFocused ? 1.0 : 0.6)
                            .opacity(isFocused ? 1.0 : 0.0)
                            .animation(.default, value: isFocused)
                        Spacer()
                        PodcastImage(uuid: lastPodcast, size: .page)
                            .frame(width: Layout.imageSize, height: Layout.imageSize)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: .pcShadowLight, radius: 37.5, x: 0, y: 0)
                            .offset(x: isFocused ? Layout.imageSize : 0)
                            .scaleEffect(isFocused ? 1.0 : 0.6)
                            .opacity(isFocused ? 1.0 : 0.0)
                            .animation(.default, value: isFocused)
                    }
                }
            }
            .padding(.horizontal, 36)
        }
        .padding(.horizontal, 36)
        .frame(height: Layout.cardHeight)
        .background(style(for: model.category))
        .clipped()
        .task {
            await model.load()
        }
    }

    @ViewBuilder
    func style(for category: DiscoverCategory) -> some View {
        if !isFocused {
            Color.pcBackgroundOverlay
        } else if let id = category.id {
            CategoryStyle.allCases[id % CategoryStyle.allCases.count].gradient
        } else {
            CategoryStyle.red.tintColor
        }
    }
}

#Preview {
    DiscoverCategoryCell(category: DiscoverCategory(id: 1, name: "True Crime"))
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
