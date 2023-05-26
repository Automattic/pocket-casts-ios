import SwiftUI

struct StatusPageView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var viewModel = StatusPageViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(L10n.settingsStatusDescription)
                    .foregroundColor(theme.primaryText01)
                    .padding(.top, 16)

                if !viewModel.running && !viewModel.hasRun {
                    Button() {
                        viewModel.run()
                    } label: {
                        Text(L10n.settingsStatusRun)
                            .textStyle(RoundedButton())
                    }
                }

                if viewModel.running || viewModel.hasRun {
                    VStack(spacing: 16) {
                        ForEach(viewModel.checks) { check in
                            HStack(alignment: .top, spacing: 5) {
                                switch check.status {
                                case .failure:
                                    Image(systemName: "xmark")
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(theme.support05)
                                case .success:
                                    Image(systemName: "checkmark")
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(theme.support02)
                                case .running:
                                    ProgressView()
                                        .tint(theme.primaryIcon01)
                                case .idle:
                                    Rectangle()
                                        .frame(width: 20, height: 20)
                                        .opacity(0)
                                }


                                VStack(alignment: .leading, spacing: 5) {
                                    Text(check.title)
                                        .font(style: .title3, weight: .semibold)
                                        .foregroundColor(theme.primaryText01)

                                    if check.status == .failure {
                                        Text(check.failureMessage)
                                            .font(style: .callout)
                                            .foregroundColor(theme.support05)
                                    }

                                    Text(check.description)
                                        .font(style: .callout)
                                        .foregroundColor(theme.primaryText02)
                                }

                                Spacer()
                            }
                        }
                    }

                    Button() {
                        viewModel.run()
                    } label: {
                        Text(L10n.tryAgain)
                            .textStyle(RoundedButton())
                            .opacity(viewModel.running ? 0.5 : 1)
                    }
                    .disabled(viewModel.running)
                }
            }
        }
        .padding(.horizontal, 16)
        .navigationTitle(L10n.settingsStatusPage)
        .applyDefaultThemeOptions()
    }
}

struct StatusPageView_Previews: PreviewProvider {
    static var previews: some View {
        StatusPageView()
            .setupDefaultEnvironment()
    }
}
