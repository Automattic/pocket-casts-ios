import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI
import UIKit

/// Shown in place of the app when its database can't be opened. The database is left on disk
/// untouched, so the only ways out of here are contacting support and sending them a copy of it.
class DatabaseErrorViewController: ThemedHostingController<DatabaseErrorView> {
    private let viewModel: DatabaseErrorViewModel

    init(error: Error) {
        viewModel = DatabaseErrorViewModel(error: error)
        super.init(rootView: DatabaseErrorView(viewModel: viewModel), background: \.primaryUi01)
        viewModel.presenter = self
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@MainActor
class DatabaseErrorViewModel {
    let details: String

    weak var presenter: UIViewController?

    private let emailHelper = EmailHelper()
    private var databaseExport: DatabaseExport?
    private var loadingAlert: ShiftyLoadingAlert?

    init(error: Error) {
        details = "\(error)\n\n\(DataManager.pathToDb())"
    }

    func contactSupport() {
        guard let presenter else { return }

        emailHelper.presentSupportDialog(presenter, type: .support)
    }

    func exportDatabase() {
        guard let presenter else { return }

        databaseExport = DatabaseExport()

        loadingAlert = ShiftyLoadingAlert(title: L10n.exportingDatabase)
        loadingAlert?.showAlert(presenter, hasProgress: false, completion: { [weak self] in
            Task {
                let url = await self?.databaseExport?.export()
                self?.shareExport(url: url)
            }
        })
    }

    private func shareExport(url: URL?) {
        loadingAlert?.hideAlert(false)
        loadingAlert = nil

        guard let presenter else { return }

        guard let url else {
            SJUIUtils.showAlert(title: L10n.settingsExportError, message: nil, from: presenter)
            return
        }

        let shareSheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        shareSheet.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.databaseExport?.cleanup(url: url)
            self?.databaseExport = nil
        }
        shareSheet.popoverPresentationController?.sourceView = presenter.view
        shareSheet.popoverPresentationController?.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)

        presenter.present(shareSheet, animated: true)
    }
}

struct DatabaseErrorView: View {
    @EnvironmentObject private var theme: Theme
    let viewModel: DatabaseErrorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(AppTheme.color(for: .support05, theme: theme))
                    .padding(.bottom, 8)

                Text(L10n.databaseErrorTitle)
                    .font(.system(size: 24, weight: .bold))
                    .textStyle(PrimaryText())

                Text(L10n.databaseErrorMessage)
                    .font(.system(size: 16))
                    .textStyle(SecondaryText())

                Text(L10n.databaseErrorKeepAppInstalled)
                    .font(.system(size: 16))
                    .textStyle(SecondaryText())

                details

                Button {
                    viewModel.contactSupport()
                } label: {
                    Text(L10n.databaseErrorContactSupport)
                        .textStyle(RoundedButton())
                }
                .padding(.top, 8)

                Button {
                    viewModel.exportDatabase()
                } label: {
                    Text(L10n.exportDatabase)
                        .textStyle(BorderButton())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(AppTheme.color(for: .primaryUi01, theme: theme).ignoresSafeArea())
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.databaseErrorDetails)
                .font(.system(size: 14, weight: .semibold))
                .textStyle(PrimaryText())

            Text(viewModel.details)
                .font(.system(size: 13, design: .monospaced))
                .textStyle(SecondaryText())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppTheme.color(for: .primaryUi02, theme: theme))
                .cornerRadius(ViewConstants.cornerRadius)
        }
    }
}
