import SwiftUI

struct UpgradeLandingView: View {
    var body: some View {
        ZStack {
            Color(hex: "121212")

            ScrollViewIfNeeded {
                VStack {
                    PlusLabel(L10n.plusMarketingTitle, for: .title)

                    HStack {
                        Text("Yearly")
                            .foregroundColor(.white)
                        Text("Monthly")
                            .foregroundColor(.white)
                    }

                    VStack {
                        Text("Plus")
                            .foregroundColor(.white)
                        Text("$39.99 /year")
                            .foregroundColor(.white)
                        Text("Take your podcasting experience to the next level with exclusive access to features and customization options.")
                            .foregroundColor(.white)

                        Text("Desktop apps")
                            .foregroundColor(.white)
                        Text("Folders")
                            .foregroundColor(.white)
                        Text("10GB cloud storage")
                            .foregroundColor(.white)
                        Text("Apple Watch playback")
                            .foregroundColor(.white)
                        Text("Extra themes & icons")
                            .foregroundColor(.white)
                        Text("The undying gratitude of everyone here at Pocket Casts")
                            .foregroundColor(.white)

                        Button("Subscribe to Plus") {
                            
                        }

                    }
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
