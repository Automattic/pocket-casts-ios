import SwiftUI

struct ImportLandingView: View {
    @EnvironmentObject var theme: Theme
    let viewModel: ImportViewModel

    var body: some View {
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
                        ForEach(viewModel.availableSources) { importSource in
                            ImportSourceRow(importSource: importSource) {
                                viewModel.didSelect(importSource)
                            }
                        }
                    }

                    Spacer()
                }.padding([.leading, .trailing], 24)
            }.padding(.top, 16).padding(.bottom)
                .background(AppTheme.color(for: .primaryUi01, theme: theme).ignoresSafeArea())
    }
}

private struct ImportSourceRow: View {
    @EnvironmentObject var theme: Theme
    let importSource: ImportViewModel.ImportSource
    let action: () -> Void

    init(importSource: ImportViewModel.ImportSource, _ action: @escaping () -> Void) {
        self.importSource = importSource
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                Image(importSource.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)

                Text(L10n.importInstructionsImportFrom(importSource.displayName))
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

extension ImportViewModel.ImportSource {
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
        case .opmlFromURL:
            return "opml_from_url"
        }
    }
}
