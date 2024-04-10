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

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if let categories, let popular {
                    CategoriesPillsView(pillCategories: popular, overflowCategories: categories, selectedCategory: $observable.selectedCategory.animation(.easeOut(duration: 0.25)))
                        .environmentObject(Theme.sharedTheme)
                } else {
                    PlaceholderPillsView()
                }
            }
            .padding(16)
        }
        .task(id: discoverItemObservable.item?.source) {
            guard let source = discoverItemObservable.item?.source else { return }
            let categories = await DiscoverServerHandler.shared.discoverCategories(source: source)
            self.categories = categories
            popular = categories.filter {
                guard let id = $0.id else { return false }
                return discoverItemObservable.item?.popular?.contains(id) == true
            }
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
            .environmentObject(Theme.sharedTheme)
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
        })
        .buttonStyle(CategoryButtonStyle())
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
