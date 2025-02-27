import PocketCastsDataModel
import SwiftUI

struct SuggestedFoldersUpSellView: View {
    @Environment(\.dismiss) var dismissAction
    @EnvironmentObject var theme: Theme
    @ObservedObject var model: SuggestedFoldersModel

    init(model: SuggestedFoldersModel = SuggestedFoldersModel()) {
        self.model = model
    }

    var body: some View {
        Group {
            switch model.loadingState {
            case .loaded:
                mainBody
            default:
                loadingView
            }
        }
        .task {
            await model.load()
        }
        .applyDefaultThemeOptions()
    }

    var loadingView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                LoadingView()
                Spacer()
            }
            Spacer()
        }
        .applyDefaultThemeOptions()
    }

    var mainBody: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
            foldersView
            Spacer()
            Group {
                Text(L10n.suggestedFoldersUpsellTitle)
                    .font(.title2)
                    .textStyle(PrimaryText())
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.suggestedFoldersUpsellDescription)
                    .font(.body)
                    .textStyle(SecondaryText())
                    .fixedSize(horizontal: false, vertical: true)
            }.multilineTextAlignment(.center)
            Spacer()
            Button {
                Analytics.track(.suggestedFoldersPaywallModalUseTheseFoldersTapped, properties: [:])
                dismissAction()
            } label: {
                Text(L10n.suggestedFoldersUseSuggestedFolders)
                    .textStyle(RoundedButton())
            }
            Spacer().frame(height: 8)
            Button {
                Analytics.track(.suggestedFoldersPaywallModalMaybeLaterTapped, properties: [:])
                dismissAction()
            } label: {
                Text(L10n.maybeLater)
                    .textStyle(BorderButton())
            }
            Spacer().frame(height: 8)
        }
        .padding(.horizontal, 16)
        .onAppear {
            Analytics.track(.suggestedFoldersPaywallModalShown, properties: [:])
        }
    }

    var foldersView: some View {
        LazyHGrid(rows: [GridItem(.adaptive(minimum: 110, maximum: 130))], alignment: .center, spacing: 6) {
            ForEach(Array<SuggestedFolder>(model.folders.prefix(3))) { folder in
                SuggestedFolderPreviewWrapper(folder: folder)
                    .cornerRadius(4)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(height: 130)
            }
        }
    }
}

struct SuggestedFoldersUpSellView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestedFoldersView(completion: { _ in })
            .environmentObject(Theme(previewTheme: .light))
    }
}
