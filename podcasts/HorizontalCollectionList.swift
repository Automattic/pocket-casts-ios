import SwiftUI

class HorizontalCollectionModel: ObservableObject {

    @Published var colors: [Color] = [.blue, .green, .yellow, .orange, .pink, .purple, .cyan, .brown, .gray, .indigo]
}

struct HorizontalCollectionList: View {

    @EnvironmentObject var theme: Theme
    @StateObject var model: HorizontalCollectionModel = HorizontalCollectionModel()

    var body: some View {
        VStack {
            HStack {
                Text("Guest List")
                    .foregroundStyle(theme.primaryText01)
                    .font(.title2.bold())
                Spacer()
                Text(L10n.discoverShowAll)
                    .foregroundStyle(theme.support03)
                    .font(.footnote.bold())
            }
            ScrollView([.horizontal]) {
                HStack {
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .foregroundColor(.red)
                        VStack() {
                            Text("Title")
                                .foregroundStyle(.white)
                                .font(.footnote.bold())
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            Text("Subtitle")
                                .foregroundStyle(.white)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            Spacer().frame(height: 12)
                        }
                            .foregroundColor(.clear)
                            .frame(minWidth: 179, minHeight: 74)
                            .background(
                                LinearGradient(
                                    stops: [
                                        Gradient.Stop(color: Color(red: 0.16, green: 0.05, blue: 0.02).opacity(0), location: 0.00),
                                        Gradient.Stop(color: Color(red: 0.09, green: 0.05, blue: 0.03), location: 1.00),
                                    ],
                                    startPoint: UnitPoint(x: 0.5, y: 0),
                                    endPoint: UnitPoint(x: 0.5, y: 0.7)
                                )
                            )
                    }
                    .frame(width: 0, height: 210)
                    .cornerRadius(4)
                    LazyHGrid(rows: [GridItem(.adaptive(minimum: 100, maximum: 100))], alignment: .center, spacing: 6) {
                        ForEach(model.colors, id: \.hashValue) { color in
                            HStack {
                                Rectangle()
                                    .foregroundColor(color)
                                    .cornerRadius(4)
                                    .frame(minHeight: 100, maxHeight: 100)
                                    .aspectRatio(1, contentMode: .fit)
                                VStack {
                                    Text("Title")
                                    Text("Subtitle")
                                }
                                Spacer()
                                Image("discover_add")
                                    .tint(theme.primaryIcon02)
                            }
                            //.frame(width: 371)
                            .background(.gray)
                            .withScrollTargetLayout()
                        }
                    }
                }
            }
            .withPaging()
            PageIndicatorView(numberOfItems: model.colors.count / 2, currentPage: 0)
                .foregroundColor(theme.primaryText01)
                .padding(.top, 16.0)
        }
        //.padding(16)
    }
}

struct WithScrollTargetModifier: ViewModifier {

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 0.8)
        } else {
            content
        }
    }
}

extension View {
    func withScrollTargetLayout() -> some View {
        self.modifier(WithScrollTargetModifier())
    }
}

struct WithPagingModifier: ViewModifier {

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.scrollTargetBehavior(.paging)
        } else {
            content
        }
    }
}

extension View {
    func withPaging() -> some View {
        self.modifier(WithPagingModifier())
    }
}

struct HorizontalCarouselList_Previews: PreviewProvider {
    static var previews: some View {
        HorizontalCollectionList()
            .environmentObject(Theme(previewTheme: .light))
            .frame(height: 300)
    }
}
