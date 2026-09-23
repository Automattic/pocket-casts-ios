import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import Kingfisher

struct DiscoverCategoryCell: View {
    @State var model: DiscoverCategoryModel
    let colorIndex: Int

    @Environment(\.isFocused) var isFocused: Bool

    enum Layout {
        static let imageSize = CGFloat(156)
        static let rotationEffect = CGFloat(15)
        static let cardHeight = CGFloat(258)
        static let iconSize = CGFloat(48)
    }

    init(category: DiscoverCategory, colorIndex: Int, source: String) {
        _model = State(wrappedValue: DiscoverCategoryModel(category: category, source: source))
        self.colorIndex = colorIndex
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
                        .accessibilityHidden(true)
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
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .pcShadowLight, radius: 37.5, x: 0, y: 0)
                            .offset(x: isFocused ? -Layout.imageSize + 8 : -Layout.imageSize * 2)
                            .scaleEffect(isFocused ? 1.0 : 0.85)
                            .opacity(isFocused ? 1.0 : 0.0)
                            .animation(.spring(duration: 0.35, bounce: 0.35), value: isFocused)
                        Spacer()
                        PodcastImage(uuid: lastPodcast, size: .page)
                            .frame(width: Layout.imageSize, height: Layout.imageSize)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .pcShadowLight, radius: 37.5, x: 0, y: 0)
                            .offset(x: isFocused ? Layout.imageSize - 8 : Layout.imageSize * 2)
                            .scaleEffect(isFocused ? 1.0 : 0.85)
                            .opacity(isFocused ? 1.0 : 0.0)
                            .animation(.spring(duration: 0.35, bounce: 0.35), value: isFocused)
                    }
                }
            }
            .padding(.horizontal, 36)
        }
        .padding(.horizontal, 36)
        .frame(height: Layout.cardHeight)
        .background(style(for: colorIndex))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .focusedCardDepth(isFocused: isFocused, cornerRadius: 16)
        .task {
            await model.load()
        }
    }

    @ViewBuilder
    func style(for colorIndex: Int) -> some View {
        if !isFocused {
            Color.pcBackgroundOverlay
        } else {
            CategoryStyle.assignableCases[colorIndex % CategoryStyle.assignableCases.count].gradient
        }
    }
}

#Preview {
    DiscoverCategoryCell(category: DiscoverCategory(id: 1, name: "True Crime"), colorIndex: 0, source: DiscoverAnalytics.searchSource)
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
