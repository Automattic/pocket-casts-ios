import SwiftUI
import PocketCastsServer

struct Category {
    let title: String
    let image: String
}

struct CategoriesSelectorView: View {
    @ObservedObject var discoverItemObservable: CategoriesSelectorViewController.DiscoverItemObservable

    @State private var categories: [DiscoverCategory]?
    @State private var popular: [DiscoverCategory]?

    @EnvironmentObject private var theme: Theme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if let categories, let popular {
                    CategoriesPillsView(pillCategories: popular, overflowCategories: categories, selectedCategory: $discoverItemObservable.selectedCategory.animation(.easeOut(duration: 0.25)))
                } else {
                    PlaceholderPillsView()
                }
            }
            .padding(.top, 2)
            .padding(.bottom, 16)
            .padding(.horizontal, 16)
        }
        .background(theme.secondaryUi01)
        .task(id: discoverItemObservable.item?.source) {
            let result = await discoverItemObservable.load()
            self.categories = result?.categories
            self.popular = discoverItemObservable.item?.popular?.compactMap({ orderedItem in
                result?.popular.first(where: { $0.id == orderedItem }) ?? result?.categories.first(where: { $0.id == orderedItem })
            }) ?? result?.popular
        }
    }
}

struct PlaceholderPillsView: View {
    var body: some View {
        ForEach(0..<10) { _ in
            Button(action: {}, label: {
                Text("Placeholder")
            })
            .buttonStyle(CategoryButtonStyle())
            .redacted(reason: .placeholder)
        }
    }
}

struct CategoriesPillsView: View {
    let pillCategories: [DiscoverCategory]
    let overflowCategories: [DiscoverCategory]
    @Binding var selectedCategory: DiscoverCategory?

    @State private var showingCategories = false

    @Namespace private var animation

    var body: some View {
        if let selectedCategory {
            CloseButton(selectedCategory: $selectedCategory)
            CategoryButton(category: selectedCategory, selectedCategory: $selectedCategory)
                .matchedGeometryEffect(id: selectedCategory.id, in: animation)
        } else {
            Button(action: {
                showingCategories.toggle()
            }, label: {
                HStack {
                    Text("All Categories")
                    Image(systemName: "chevron.down")
                }
            })
            .buttonStyle(CategoryButtonStyle())
            ForEach(pillCategories, id: \.id) { category in
                CategoryButton(category: category, selectedCategory: $selectedCategory)
                .matchedGeometryEffect(id: category.id, in: animation)
            }
            .sheet(isPresented: $showingCategories) {
                CategoriesModalPicker(categories: overflowCategories, selectedCategory: $selectedCategory)
                    .modify {
                        if #available(iOS 16.0, *) {
                            $0.presentationDetents([.medium, .large])
                                .presentationDragIndicator(.hidden)
                        } else {
                            $0
                        }
                    }
            }
            .onChange(of: selectedCategory) { _ in
                showingCategories = false
            }
        }
    }
}

extension DiscoverCategory: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct CloseButton: View {
    @Binding var selectedCategory: DiscoverCategory?

    var body: some View {
        Button(action: {
            self.selectedCategory = nil
        }, label: {
            Image(systemName: "xmark")
                .imageScale(.small)
        })
        .buttonStyle(CategoryButtonStyle(cornerStyle: .circle))
    }
}

struct CategoryButton: View {
    let category: DiscoverCategory

    @Binding var selectedCategory: DiscoverCategory?

    var isSelected: Bool {
        category.id == selectedCategory?.id
    }

    var body: some View {
        Button(action: {
            selectedCategory = category
        }, label: {
            Text(category.name ?? "")
        })
        .buttonStyle(CategoryButtonStyle(isSelected: isSelected))
    }
}

// MARK: Previews

#Preview("unselected") {
    let category = DiscoverCategory(id: 0, name: "Test")
    let observable = CategoriesSelectorViewController.DiscoverItemObservable {
        return ([category], [category])
    }
    return ScrollView(.vertical) {
        CategoriesSelectorView(discoverItemObservable: observable)
            .frame(width: 400)
            .previewWithAllThemes()
    }
}

#Preview("selected") {
    let category = DiscoverCategory(id: 0, name: "Test")
    let observable = CategoriesSelectorViewController.DiscoverItemObservable {
        return ([category], [category])
    }
    return ScrollView(.vertical) {
        CategoriesSelectorView(discoverItemObservable: observable)
            .frame(width: 400)
            .previewWithAllThemes()
            .onAppear {
                observable.selectedCategory = category
            }
    }
}
