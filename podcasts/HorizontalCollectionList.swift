import SwiftUI
import Foundation

class HorizontalCollectionModel: ObservableObject {

    @Published var colors: [Color] = [.blue, .green, .yellow, .orange, .pink, .purple, .cyan, .brown, .indigo]

    var list: [[Color?]] {
        return colors.pairs()
    }
}

extension Color: @retroactive Identifiable {

    public var id: String {
        return description
    }
}

struct HorizontalCollectionList: View {

    @StateObject var model: HorizontalCollectionModel = HorizontalCollectionModel()

    var header: some View {
        HStack {
            Text("Guest List")
                .foregroundStyle(.black)
                .font(.title2.bold())
            Spacer()
            Text("Show All")
                .foregroundStyle(.black)
                .font(.footnote.bold())
        }
        .padding(8)
    }

    var poster: some View {
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
        .cornerRadius(4)
    }

    @ViewBuilder
    func row(color: Color) -> some View {
        HStack(spacing: 10) {
            Rectangle()
                .foregroundColor(color)
                .cornerRadius(4)
                .frame(width: 100, height: 100)
                .aspectRatio(1, contentMode: .fit)
            VStack(alignment: .leading) {
                HStack {
                    Text(color.description)
                    Spacer()
                }
                Text("Subtitle")
            }
            Image(systemName: "plus")
                .tint(.blue)
            Spacer()
        }
    }

    @State var currentPage: Int? = 0

    var body: some View {
        let pairs = model.list
        VStack(spacing: 0) {
            header
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    HStack {
                        Button("Start") {
                            withAnimation {
                                currentPage = 0
                                proxy.scrollTo(currentPage, anchor: .leading)
                            }
                        }
                        Spacer()
                        Text("\(currentPage )")
                        Spacer()
                        Button("End") {
                            withAnimation {
                                currentPage = pairs.count
                                proxy.scrollTo(currentPage, anchor: .leading)
                            }
                        }
                    }
                    ScrollView([.horizontal]) {
                        LazyHStack(spacing: 5) {
                            poster
                                .id(0)
                            ForEach(0..<pairs.count, id: \.self) { index in
                                VStack {
                                    ForEach(pairs[index], id: \.self) { color in
                                        if let color {
                                            row(color: color)
                                        } else {
                                            HStack() {
                                                Rectangle().foregroundColor(.clear)
                                            }
                                            .frame(height: 100)
                                        }
                                    }
                                }
                                .id(index + 1)
                                .padding(.horizontal, 10)
                                .frame(width: max(geometry.size.width - 30, 0))
                                .background(.gray)
                            }
                        }
                        .withScrollTargetLayout()
                        .background(.yellow)
                    }
                    .withPaging(minPage: 0, maxPage: pairs.count, currentPage: $currentPage, scrollProxy: proxy)
                }
            }
        }
        .frame(height: 300)
    }
}

// MARK: - Special modifier to support versions previous than iOS 17
struct WithScrollTargetModifier: ViewModifier {

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.scrollTargetLayout()
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

    let minPage: Int
    let maxPage: Int
    @Binding var currentPage: Int?
    let scrollProxy: ScrollViewProxy

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentPage)
        } else {
            content.scrollDisabled(true)
                .gesture(DragGesture(minimumDistance: 3, coordinateSpace: .local)
                    .onEnded({ value in
                        if value.translation.width < 0 {
                            withAnimation {
                                currentPage = min(maxPage, (currentPage ?? 0) + 1)
                                scrollProxy.scrollTo(currentPage, anchor: .leading)
                            }
                        }

                        if value.translation.width > 0 {
                            withAnimation {
                                currentPage = max(minPage, (currentPage ?? 0) - 1)
                                scrollProxy.scrollTo(currentPage, anchor: .leading)
                            }
                        }
                    }))
        }
    }
}


extension View {
    func withPaging(minPage: Int, maxPage: Int, currentPage: Binding<Int?>, scrollProxy: ScrollViewProxy) -> some View {
        return self.modifier(WithPagingModifier(minPage: minPage, maxPage: maxPage, currentPage: currentPage, scrollProxy: scrollProxy))
    }
}

struct HorizontalCarouselList_Previews: PreviewProvider {
    static var previews: some View {
        HorizontalCollectionList()
            .frame(height: 300)
    }
}
