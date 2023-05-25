import SwiftUI

struct StatusPageView: View {
    @EnvironmentObject var theme: Theme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(L10n.settingsStatusDescription)
                    .foregroundColor(theme.primaryText01)
                Button() {

                } label: {
                    Text(L10n.settingsStatusRun)
                        .textStyle(RoundedButton())
                }

                VStack(spacing: 16) {
                    HStack(alignment: .top) {
                        Image(systemName: "xmark")
                            .frame(width: 22, height: 22)
                            .foregroundColor(theme.support05)

                        VStack(alignment: .leading) {
                            Text("Title")
                                .font(style: .title3, weight: .semibold)
                                .foregroundColor(theme.primaryText01)
                            Text("Error description")
                                .font(style: .callout)
                                .foregroundColor(theme.support05)
                            Text("Subtitle")
                                .font(style: .callout)
                                .foregroundColor(theme.secondaryIcon02)
                        }

                        Spacer()
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "checkmark")
                            .frame(width: 22, height: 22)
                            .foregroundColor(theme.support02)

                        VStack(alignment: .leading) {
                            Text("Title")
                                .font(style: .title3, weight: .semibold)
                                .foregroundColor(theme.primaryText01)
                            Text("Subtitle")
                                .font(style: .callout)
                                .foregroundColor(theme.secondaryIcon02)
                        }

                        Spacer()
                    }
                }

                HStack {
                    Button() {

                    } label: {
                        Text(L10n.tryAgain)
                            .textStyle(RoundedButton())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .navigationTitle("Status Page")
        .applyDefaultThemeOptions()
    }
}

struct StatusPageView_Previews: PreviewProvider {
    static var previews: some View {
        StatusPageView()
            .setupDefaultEnvironment()
    }
}
