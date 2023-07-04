import SwiftUI

struct WhatsNewView: View {
    var theme: Theme = .sharedTheme

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .top) {
                Rectangle()
                    .frame(height: 195)

                HStack {
                    Spacer()
                    Button {

                    } label: {
                        ZStack {
                            Image("close")
                                .foregroundColor(.white)
                        }
                        .frame(width: 44, height: 44)
                    }
                }
            }
            Text("Autoplay is here!")
                .font(style: .title3, weight: .bold)
                .padding(.horizontal)
                .foregroundColor(theme.primaryText01)
            Text("If your Up Next queue is empty, Pocket Casts can autoplay episodes from the list you started playing it — either a specific podcast, a filter, downloaded episodes or your own files.")
                .font(style: .subheadline)
                .foregroundColor(theme.secondaryText02)
                .padding(.horizontal)
            Button("Enable it") {}
                .buttonStyle(RoundedDarkButton(theme: theme))
                .padding(.horizontal)
                .padding(.bottom)
        }
        .frame(width: 340)
        .background(.white)
        .cornerRadius(5)
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView()
            .environmentObject(Theme(previewTheme: .light))
    }
}
