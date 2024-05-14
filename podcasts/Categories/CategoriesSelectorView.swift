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
        Group {
            if let categories, let popular {
                CategoriesPillsView(pillCategories: popular,
                                    overflowCategories: categories,
                                    selectedCategory: $discoverItemObservable.selectedCategory.animation(.easeOut(duration: 0.25)),
                                    region: discoverItemObservable.region)
            } else {
                PlaceholderPillsView()
            }
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

    let region: String?

    @State private var showingCategories = false

    @Namespace private var animation

    private enum Constants {
        static let buttonInsets: EdgeInsets = EdgeInsets(top: 2, leading: 16, bottom: 16, trailing: 16)
    }

    var body: some View {
        if let selectedCategory {
            HStack {
                CloseButton(selectedCategory: $selectedCategory)
                CategoryButton(category: selectedCategory, selectedCategory: $selectedCategory, region: region)
                    .matchedGeometryEffect(id: selectedCategory.id, in: animation)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Constants.buttonInsets)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    allCategoriesButton
                    categoryButtons
                }
                .padding(Constants.buttonInsets)
            }
        }
    }

    @ViewBuilder private var allCategoriesButton: some View {
        Button(action: {
            showingCategories.toggle()
            Analytics.track(.discoverCategoriesPillTapped, properties: ["name": "all", "region": region ?? "none", "id": -1])
        }, label: {
            HStack {
                Text("All Categories")
                Image(systemName: "chevron.down")
            }
        })
        .buttonStyle(CategoryButtonStyle())
        .sheet(isPresented: $showingCategories) {
            CategoriesModalPicker(categories: overflowCategories, selectedCategory: $selectedCategory, region: region)
                .modify {
                    if #available(iOS 16.0, *) {
                        $0.presentationDetents([.medium, .large])
                            .presentationDragIndicator(.hidden)
                    } else {
                        $0
                    }
                }
        }
        .onChange(of: showingCategories) { isShowing in
            if isShowing {
                Analytics.track(.discoverCategoriesPickerShown, properties: ["region": region ?? "none"])
            } else {
                Analytics.track(.discoverCategoriesPickerClosed, properties: ["region": region ?? "none"])
            }
        }
        .onChange(of: selectedCategory) { _ in
            showingCategories = false
        }
    }

    @ViewBuilder private var categoryButtons: some View {
        ForEach(pillCategories, id: \.id) { category in
            CategoryButton(category: category, selectedCategory: $selectedCategory, region: region)
                .matchedGeometryEffect(id: category.id, in: animation)
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
            Analytics.track(.discoverCategoryCloseButtonTapped)
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

    let region: String?

    var isSelected: Bool {
        category.id == selectedCategory?.id
    }

    var body: some View {
        Button(action: {
            selectedCategory = category
            Analytics.track(.discoverCategoriesPillTapped, properties: ["name": category.name ?? "none", "region": region ?? "none", "id": category.id ?? -1])
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
