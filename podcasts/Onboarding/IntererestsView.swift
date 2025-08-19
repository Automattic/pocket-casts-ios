import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct InterestsView: View {

    @State var categories: [DiscoverCategory] = []
    @State var layout: DiscoverLayout?
    @State var showingImport = false

    @EnvironmentObject var theme: Theme

    var body: some View {
        Group {
            if layout != nil {
                ZStack(alignment: .bottom) {
                    ScrollView(.vertical) {
                        VStack(spacing: 16) {
                            header
                            ForEach(categories, id: \.id) { category in
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(category.name ?? "Unknown")
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(theme.primaryText01)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                }
                            }
                            showMoreCategoriesButton
                        }
                        .padding(.bottom, 120)
                    }
                    .fadeGradient(bottomOffset: 50)

                    VStack {
                        Button(action: {
                            //TODO: Implement this
                        }) {
                            Text(L10n.continue)
                                .textStyle(RoundedButton())
                        }
                        .padding(.horizontal)
                        .padding(.top, 2)
                        .padding(.bottom)
                    }
                    .background(theme.primaryInteractive02)
                    .background(.ultraThinMaterial)
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primaryIcon01))
                    .task {
                        let page = await DiscoverServerHandler.shared.discoverPage()
                        guard let layout = page.0 else {
                            return
                        }

                        let categoriesItem = layout.layout?.first { item in
                            item.type == "categories"
                        }
                        guard let categoriesItem else {
                            return
                        }
                        categories = await DiscoverServerHandler.shared.discoverCategories(source: categoriesItem.source ?? "", authenticated: categoriesItem.isAuthenticated)
                        self.layout = layout
                    }
            }
        }
        .background(theme.primaryInteractive02)
    }

    var header: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(L10n.eoyNotNow) {

                }
                .tint(theme.primaryInteractive01)
            }
            .padding(.horizontal, 20)

            VStack(alignment: .center, spacing: 16) {
                Text(L10n.interestsTitle)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.primaryText01)
                Text(L10n.interestsSubtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.primaryText02)
            }
            .padding(.horizontal, 30)
        }
        .padding(.top, 20)
    }

    var showMoreCategoriesButton: some View {
        HStack {
            Spacer()
            Button(L10n.interestsShowMoreCategories) {

            }
            .tint(theme.primaryInteractive01)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview("Live") {
    InterestsView()
        .environmentObject(Theme(previewTheme: .extraDark))
}
