import SwiftUI
import PocketCastsServer
import Kingfisher

struct CategoriesModalPicker: View {
    let categories: [DiscoverCategory]

    @Binding var selectedCategory: DiscoverCategory?

    let region: String?

    @EnvironmentObject var theme: Theme

    private enum Constants {
        enum Padding {
            static let title = EdgeInsets(top: 26, leading: 20, bottom: 4, trailing: 20)
            static let cell = EdgeInsets(top: 25, leading: 20, bottom: 25, trailing: 20)
        }
        static let imageSize: CGFloat = 24
        static let cellSpacing: CGFloat = 20
    }

    // MARK: Colors
    private var separator: Color {
        theme.primaryField03
    }
    private var background: Color {
        theme.primaryUi01
    }
    private var titleForeground: Color {
        theme.support01
    }
    private var cellForeground: Color {
        theme.primaryText01
    }

    private var selectedBackground: Color {
        theme.primaryUi01Active
    }

    var body: some View {
        VStack(alignment: .leading) {
            title
                .padding(Constants.Padding.title)
            List {
                ForEach(categories, id: \.self) { category in
                    cell(category)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(background)
                        .listRowSeparatorTint(separator)
                        .modify {
                            if #available(iOS 16.0, *) {
                                $0.alignmentGuide(.listRowSeparatorLeading) { d in
                                    d[.leading] + Constants.Padding.cell.leading
                                }
                                .alignmentGuide(.listRowSeparatorTrailing) { d in
                                    d[.trailing] - Constants.Padding.cell.trailing
                                }
                            }
                        }
                }
            }
            .listStyle(.plain)
        }
        .background(background)
    }

    @ViewBuilder var title: some View {
        Text("Select a Category".uppercased())
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(titleForeground)
    }

    @ViewBuilder func cell(_ category: DiscoverCategory) -> some View {
        HStack(spacing: Constants.cellSpacing) {
            if let icon = category.icon, let url = URL(string: icon) {
                KFImage(url)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: Constants.imageSize, height: Constants.imageSize)
            }
            Text(category.name ?? "")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.Padding.cell)
        .buttonize {
            selectedCategory = category
            Analytics.track(.discoverCategoriesPickerPick, properties: ["id": category.id ?? -1, "name": category.name ?? "all", "region": region ?? "none"])
        } customize: { config in
            config.label
                .foregroundStyle(cellForeground)
                .background(config.isPressed ? selectedBackground : background)
        }
    }
}
