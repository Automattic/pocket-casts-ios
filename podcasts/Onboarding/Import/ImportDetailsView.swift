import SwiftUI

struct ImportDetailsView: View {
    enum OPMLImportResult {
        case none
        case success
        case failure
    }

    @EnvironmentObject var theme: Theme
    @Environment(\.presentationMode) var presentationMode

    @State var opmlURLText = ""
    @State var opmlURLImportResult: OPMLImportResult = .none
    @State var opmlImportInProgress: Bool = false
    @State var opmlButtonTitle: String = L10n.import

    let importSource: ImportViewModel.ImportSource
    let viewModel: ImportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollViewIfNeeded {
                VStack(alignment: .leading, spacing: 16) {
                    Image(importSource.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)

                    Text(L10n.importInstructionsImportFrom(importSource.displayName))
                        .font(size: 31, style: .largeTitle, weight: .bold, maxSizeCategory: .extraExtraExtraLarge)
                        .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                        .fixedSize(horizontal: false, vertical: true)

                    appInstructions

                    if importSource.id == .opmlFromURL {
                        opmlImportView
                    }

                    Spacer()
                }.padding([.leading, .trailing], Constants.horizontalPadding)
            }

            // Hide button for other
            if !importSource.hideButton {
                if importSource.id == .opmlFromURL {
                   opmlViewButton
                } else {
                    Button(importSource.id == .applePodcasts ? L10n.importInstructionsInstallShortcut : L10n.importInstructionsOpenIn(importSource.displayName)) {
                        viewModel.openApp(importSource)
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
        let lines = importSource.steps.split(separator: "\n").map { String($0).trim() }
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
                .autocapitalization(.none)
                .requiredStyle(opmlURLImportResult == .failure)
                .keyboardType(.URL)

            switch opmlURLImportResult {
            case .none: Text("")
            case .success:
                Text(L10n.opmlImportSucceededTitle)
                    .foregroundColor((ThemeColor.support02(for: theme.activeTheme).color))
            case .failure:
                Text(L10n.opmlImportFailedTitle)
                    .foregroundColor(ThemeColor.support05(for: theme.activeTheme).color)
            }

            if opmlImportInProgress {
                ProgressView(L10n.opmlImporting)
            }
        }
    }

    private var opmlViewButton: some View {
        Button(action: {
            if opmlURLImportResult == .success {
                viewModel.navigationController?.dismiss(animated: true)
                return
            }
            opmlURLImportResult = .none
            NotificationCenter.default.addObserver(forName: Notification.Name("SJOpmlImportCompleted"), object: nil, queue: nil) { notification in
                opmlURLImportResult = .success
                opmlImportInProgress = false
            }
            NotificationCenter.default.addObserver(forName: Notification.Name("SJOpmlImportFailed"), object: nil, queue: nil) { notification in
                opmlURLImportResult = .failure
                opmlImportInProgress = false
            }

            guard let url = URL(string: opmlURLText) else {
                opmlURLImportResult = .failure
                opmlImportInProgress = false
                return
            }

            opmlImportInProgress = true
            viewModel.importFromURL(url) { success in
                if !success {
                    opmlURLImportResult = .failure
                    opmlImportInProgress = false
                }
            }
        }, label: {
            Text(opmlURLImportResult == .success ? L10n.done : L10n.import)
        })
        .buttonStyle(RoundedButtonStyle(theme: theme))
        .padding([.leading, .trailing], Constants.horizontalPadding)
    }

    private enum Constants {
        static let horizontalPadding = 24.0
    }
}
