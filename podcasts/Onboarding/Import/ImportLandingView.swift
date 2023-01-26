import SwiftUI

struct ImportLandingView: View {
    @EnvironmentObject var theme: Theme
    let viewModel: ImportViewModel

    var body: some View {
        // It's possible the user has no supported apps installed
        // In this case we'll show only 1 option, so instead we'll just show the other steps to the user
        if viewModel.installedApps.count == 1, let app = viewModel.installedApps.first {
            ImportDetailsView(app: app, viewModel: viewModel)
        } else {
            ScrollViewIfNeeded {
                VStack(alignment: .leading, spacing: 0) {
                    Text(L10n.importTitle)
                        .font(size: 31, style: .largeTitle, weight: .bold, maxSizeCategory: .extraExtraExtraLarge)
                        .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, viewModel.showSubtitle ? 0 : 32)

                    if viewModel.showSubtitle {
                        Text(L10n.importSubtitle)
                            .font(size: 18, style: .body, weight: .medium, maxSizeCategory: .extraExtraExtraLarge)
                            .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                            .padding(.bottom, 32)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.installedApps) { app in
                            AppRow(app: app) {
                                viewModel.didSelect(app)
                            }
                        }
                    }

                    Spacer()
                }.padding([.leading, .trailing], 24)
            }.padding(.top, 16).padding(.bottom)
            .background(AppTheme.color(for: .primaryUi01, theme: theme).ignoresSafeArea())
        }
    }
}

private struct AppRow: View {
    @EnvironmentObject var theme: Theme
    let app: ImportViewModel.ImportApp
    let action: () -> Void

    init(app: ImportViewModel.ImportApp, _ action: @escaping () -> Void) {
        self.app = app
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                Image(app.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)

                Text(L10n.importInstructionsImportFrom(app.displayName))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                    .fixedSize(horizontal: false, vertical: true)
                    .font(style: .subheadline, weight: .medium, maxSizeCategory: .extraExtraExtraLarge)

                Spacer()

                Image(systemName: "chevron.right")
                    .frame(minHeight: 14)
                    .font(style: .subheadline, weight: .medium, maxSizeCategory: .extraExtraExtraLarge)
                    .foregroundColor(AppTheme.color(for: .primaryIcon02, theme: theme))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(ClickyButton())
    }
}

extension ImportViewModel.ImportApp {
    var iconName: String {
        switch id {
        case .breaker:
            return "import-app-breaker"
        case .castbox:
            return "import-app-castbox"
        case .overcast:
            return "import-app-overcast"
        case .castro:
            return "import-app-castro"
        case .applePodcasts:
            return "import-app-podcasts"
        case .other:
            return "import-app-other"
        }
    }
}
