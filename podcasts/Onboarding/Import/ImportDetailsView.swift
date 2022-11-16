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
                        .shadow(color: .black.opacity(0.2), radius: 0, x: 1, y: 3)

                    Text(L10n.importInstructionsImportFrom(app.displayName))
                        .font(size: 31, style: .largeTitle, weight: .css_700)
                        .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                        .fixedSize(horizontal: false, vertical: true)

                    appInstructions

                    Spacer()
                }
            }

            // Hide button for other
            if app.id != .other {
                Button(app.id == .applePodcasts ? L10n.importInstructionsInstallShortcut : L10n.importInstructionsOpenIn(app.displayName)) {
                    viewModel.openApp(app)
                }.buttonStyle(RoundedButtonStyle(theme: theme))
            }
        }.padding(.top, 16).padding([.leading, .trailing], 24).padding(.bottom)
        .background(AppTheme.color(for: .primaryUi01, theme: theme).ignoresSafeArea())
    }

    @ViewBuilder
    private var appInstructions: some View {
        let lines = app.steps.split(separator: "\n").map { String($0).trim() }
        VStack(alignment: .leading, spacing: 20) {
           ForEach(lines, id: \.self) { line in
               Text(line)
                   .font(style: .subheadline)
                   .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                   .fixedSize(horizontal: false, vertical: true)
           }
       }
    }
}
