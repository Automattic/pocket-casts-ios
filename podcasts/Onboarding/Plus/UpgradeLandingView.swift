import SwiftUI

struct UpgradeLandingView: View {
    var body: some View {
        ZStack {

            LinearGradient(gradient: Gradient(colors: [Color(hex: "121212"), Color(hex: "121212"), Color(hex: "D4B43A"), Color(hex: "FFDE64")]), startPoint: .topLeading, endPoint: .bottomTrailing)

            ScrollViewIfNeeded {
                VStack {
                    PlusLabel(L10n.plusMarketingTitle, for: .title2)

                    HStack {
                        Text("Yearly")
                            .foregroundColor(.white)
                        Text("Monthly")
                            .foregroundColor(.white)
                    }

                    VStack {
                        VStack(alignment: .leading) {
                            HStack(spacing: 4) {
                                Image("plusGold")
                                    .padding(.leading, 8)
                                Text("Plus")
                                    .foregroundColor(.white)
                                    .font(style: .subheadline, weight: .medium)
                                    .padding(.trailing, 8)
                                    .padding(.top, 2)
                                    .padding(.bottom, 2)
                            }
                            .background(.black)
                            .cornerRadius(800)

                            Text("$39.99 /year")
                            Text("Take your podcasting experience to the next level with exclusive access to features and customization options.")

                            Text("Desktop apps")
                            Text("Folders")
                            Text("10GB cloud storage")
                            Text("Apple Watch playback")
                            Text("Extra themes & icons")
                            Text("The undying gratitude of everyone here at Pocket Casts")

                            Button("Subscribe to Plus") {

                            }
                        }
                        .padding()

                    }
                    .background(.white)
                    .cornerRadius(24)
                    .padding(.leading)
                    .padding(.trailing)
                    .shadow(color: .black.opacity(0.01), radius: 10, x: 0, y: 24)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 14)
                    .shadow(color: .black.opacity(0.09), radius: 6, x: 0, y: 6)
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.1), radius: 0, x: 0, y: 0)
                }
            }
        }
    }
}

struct UpgradeLandingView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeLandingView()
    }
}
