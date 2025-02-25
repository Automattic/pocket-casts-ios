import PocketCastsDataModel
import SwiftUI

struct SuggestedFoldersUpSellView: View {
    @Environment(\.dismiss) var dismissAction
    @EnvironmentObject var theme: Theme
    @ObservedObject var model: SuggestedFoldersModel = SuggestedFoldersModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            foldersView
            Text(L10n.suggestedFoldersUpsellTitle)
                .font(.body)
                .textStyle(PrimaryText())
            Text(L10n.suggestedFoldersUpsellDescription)
                .font(.caption)
                .textStyle(SecondaryText())
            Button {
                Analytics.track(.suggestedFoldersPaywallModalUseTheseFoldersTapped, properties: [:])
                dismissAction()
            } label: {
                Text(L10n.suggestedFoldersUseSuggestedFolders)
                    .textStyle(RoundedButton())
            }
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
        .applyDefaultThemeOptions()
    }

    var foldersView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110, maximum: 160))], alignment: .center, spacing: 6) {
            ForEach(Array<SuggestedFolder>(model.folders.prefix(3))) { folder in
                SuggestedFolderPreviewWrapper(folder: folder)
                    .cornerRadius(4)
                    .frame(minWidth: 110, maxWidth: 160)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}

struct SuggestedFoldersUpSellView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestedFoldersView(dismissAction: { _ in })
            .environmentObject(Theme(previewTheme: .light))
    }
}
