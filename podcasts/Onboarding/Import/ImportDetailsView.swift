import SwiftUI

struct ImportDetailsView: View {
    @EnvironmentObject var theme: Theme

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

                    Spacer()
                }.padding([.leading, .trailing], Constants.horizontalPadding)
            }

            // Hide button for other
            if app.id != .other {
                Button(app.id == .applePodcasts ? L10n.importInstructionsInstallShortcut : L10n.importInstructionsOpenIn(app.displayName)) {
                    viewModel.openApp(app)
                }
                .buttonStyle(RoundedButtonStyle(theme: theme))
                .padding([.leading, .trailing], Constants.horizontalPadding)
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

    private enum Constants {
        static let horizontalPadding = 24.0
    }
}
