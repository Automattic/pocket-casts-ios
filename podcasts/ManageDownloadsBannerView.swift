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

    /// The borderless style needs a fill that stands out from the Downloads list behind it. That list is only
    /// `primaryUi02` when Liquid Glass is enabled (see `DownloadsViewController`). On earlier iOS versions it is
    /// `primaryUi04`, which is the same color as the borderless fill in several themes, so the banner keeps its
    /// original fill and border there.
    private var usesBorderlessStyle: Bool {
        LiquidGlass.isEnabled
    }

    private var fillColor: Color {
        guard usesBorderlessStyle else {
            return theme.primaryUi01
        }

        return theme.activeTheme == .indigo ? theme.primaryUi01 : theme.primaryUi02Active
    }

    var body: some View {
        HStack(alignment: .top) {
            Image("cleanup")
                .foregroundColor(theme.primaryText01)
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.manageDownloadsTitle)
                    .font(.callout).fontWeight(.medium)
                    .foregroundColor(theme.primaryText01)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                Text(L10n.manageDownloadsDetail(dataModel.sizeOccupied))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .font(.footnote)
                    .foregroundColor(theme.primaryText02)
                Button() {
                    dataModel.onManageTap?()
                } label: {
                    Text(L10n.manageDownloadsAction)
                        .font(.footnote).fontWeight(.medium)
                        .foregroundColor(theme.primaryText02Selected)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer()
        }
        .padding()
        .background(fillColor)
        .cornerRadius(8)
        .overlay {
            if !usesBorderlessStyle {
                RoundedRectangle(cornerRadius: 8)
                    .inset(by: 0.25)
                    .stroke(theme.primaryText02, lineWidth: 0.5)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button() {
                dataModel.onNotNowTap?()
            } label: {
                Image("close")
                    .renderingMode(.template)
                    .foregroundColor(theme.primaryIcon02)
            }
            .padding(8)
        }
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
