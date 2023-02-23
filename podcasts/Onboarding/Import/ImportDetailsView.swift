import SwiftUI

struct ImportDetailsView: View {
    enum OPMLImportResult {
        case none
        case success
        case failure
    }
    @EnvironmentObject var theme: Theme
    @State var opmlURLText = ""
    @State var opmlImportResult: OPMLImportResult = .none
    @State var isOPMLImportLoading: Bool = false

    let app: ImportViewModel.ImportApp
    let viewModel: ImportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollViewIfNeeded {
                VStack(alignment: .leading, spacing: 16) {
                    Image(app.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)

                    Text(L10n.importInstructionsImportFrom(app.displayName))
                        .font(size: 31, style: .largeTitle, weight: .bold, maxSizeCategory: .extraExtraExtraLarge)
                        .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                        .fixedSize(horizontal: false, vertical: true)

                    appInstructions

                    if app.id == .opmlFromURL {
                        opmlImportView
                    }

                    Spacer()
                }.padding([.leading, .trailing], Constants.horizontalPadding)
            }

            // Hide button for other
            if !app.hideButton {
                if app.id == .opmlFromURL {
                   opmlViewButton
                } else {
                    Button(app.id == .applePodcasts ? L10n.importInstructionsInstallShortcut : L10n.importInstructionsOpenIn(app.displayName)) {
                        viewModel.openApp(app)
                    }
                    .buttonStyle(RoundedButtonStyle(theme: theme))
                    .padding([.leading, .trailing], Constants.horizontalPadding)
                }
            }
        }.padding(.top, 16).padding(.bottom)
            .background(AppTheme.color(for: .primaryUi01, theme: theme).ignoresSafeArea())
    }

    @ViewBuilder
    private var appInstructions: some View {
        let lines = app.steps.split(separator: "\n").map { String($0).trim() }
        VStack(alignment: .leading, spacing: 20) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(style: .subheadline, maxSizeCategory: .extraExtraExtraLarge)
                    .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var opmlImportView: some View {
        VStack {
            TextField("https://...", text: $opmlURLText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)

            switch opmlImportResult {
            case .none: Text("")
            case .success:
                Text(L10n.opmlImportSucceededTitle)
                    .foregroundColor(Color.green)
            case .failure:
                Text(L10n.opmlImportFailedTitle)
                    .foregroundColor(Color.red)
            }

            if isOPMLImportLoading {
                ProgressView(L10n.opmlImporting)
            }
        }
    }

    private var opmlViewButton: some View {
        Button(L10n.import) {
            opmlImportResult = .none
            NotificationCenter.default.addObserver(forName: Notification.Name("SJOpmlImportCompleted"), object: nil, queue: nil) { notification in
                opmlImportResult = .success
                isOPMLImportLoading = false
            }
            NotificationCenter.default.addObserver(forName: Notification.Name("SJOpmlImportFailed"), object: nil, queue: nil) { notification in
                opmlImportResult = .failure
                isOPMLImportLoading = false
            }

            guard let url = URL(string: opmlURLText) else {
                opmlImportResult = .failure
                isOPMLImportLoading = false
                return
            }

            isOPMLImportLoading = true
            viewModel.importFromURL(url) { success in
                if !success {
                    opmlImportResult = .failure
                    isOPMLImportLoading = false
                }
            }
        }
        .buttonStyle(RoundedButtonStyle(theme: theme))
        .padding([.leading, .trailing], Constants.horizontalPadding)
    }

    private enum Constants {
        static let horizontalPadding = 24.0
    }
}
