import SwiftUI
import PocketCastsUtils
import Combine

class ManageDownloadsModel: ObservableObject {

    @Published var sizeOccupied: String = ""

    let onManageTap: (() -> ())?
    let onNotNowTap: (() -> ())?

    init(initialSize: String, onManageTap: (() -> ())? = nil, onNotNowTap: (() -> ())? = nil) {
        _sizeOccupied = .init(initialValue: initialSize)
        self.onManageTap = onManageTap
        self.onNotNowTap = onNotNowTap
        loadData()
    }

    func loadData() {
        Task { [weak self] in
            var totalSize = UInt64(0)
            totalSize += EpisodeManager.downloadSizeOfUnplayedEpisodes(includeStarred: true)
            totalSize += EpisodeManager.downloadSizeOfInProgressEpisodes(includeStarred: true)
            totalSize += EpisodeManager.downloadSizeOfPlayedEpisodes(includeStarred: true)
            let sizeAsStr = SizeFormatter.shared.noDecimalFormat(bytes: Int64(totalSize))
            await MainActor.run { [weak self] in
                self?.sizeOccupied = sizeAsStr
            }
        }
    }
}

struct ManageDownloadsBannerView: View {

    @EnvironmentObject var theme: Theme

    @ObservedObject var dataModel: ManageDownloadsModel

    var body: some View {
        HStack(alignment: .top) {
            Image("cleanup")
                .foregroundColor(theme.primaryText01)
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.manageDownloadsTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.primaryText01)
                Text(L10n.manageDownloadsDetail(dataModel.sizeOccupied))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 14))
                    .foregroundColor(theme.secondaryText02)
                Button() {
                    dataModel.onManageTap?()
                } label: {
                    Text(L10n.manageDownloadsAction)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.primaryText02Selected)
                }
            }
            Spacer()
        }
        .padding()
        .background(theme.primaryUi01)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .inset(by: 0.25)
                .stroke(theme.secondaryText02, lineWidth: 0.5)
        )
    }
}

#Preview("Light") {
    ManageDownloadsBannerView(dataModel: .init(initialSize: "100 MB"))
        .environmentObject(Theme(previewTheme: .light))
        .padding(16)
        .frame(height: 132)
}

#Preview("Dark") {
    ManageDownloadsBannerView(dataModel: .init(initialSize: "100 MB"))
        .environmentObject(Theme(previewTheme: .dark))
        .padding(16)
        .frame(height: 132)
}
