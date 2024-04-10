import SwiftUI
import PocketCastsServer
import Kingfisher

struct CategoriesModalPicker: View {
    let categories: [DiscoverCategory]

    @Binding var selectedCategory: DiscoverCategory?

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

    var body: some View {
        VStack(alignment: .leading) {
            Text("Select a Category".uppercased())
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(titleForeground)
                .padding(.top, Constants.Padding.title)
                .padding(.leading, Constants.Padding.title)
            List(selection: $selectedCategory, content: {
                ForEach(categories, id: \.self) { category in
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
                    .foregroundStyle(cellForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Constants.Padding.cell)
                    .listRowSeparatorTint(separator)
                    .modify {
                        if #available(iOS 16.0, *) {
                            $0.alignmentGuide(.listRowSeparatorLeading) { d in
                                    d[.leading]
                                }
                                .alignmentGuide(.listRowSeparatorTrailing) { d in
                                    d[.trailing]
                                }
                        }
                    }
                    .listRowBackground(background)
                }
            })
            .listStyle(.plain)
        }
        .background(background)
    }
}
