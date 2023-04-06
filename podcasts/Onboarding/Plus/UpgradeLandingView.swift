import SwiftUI

struct UpgradeLandingView: View {
    var body: some View {
        ZStack {

            LinearGradient(gradient: Gradient(colors: [Color(hex: "121212"), Color(hex: "121212"), Color(hex: "D4B43A"), Color(hex: "FFDE64")]), startPoint: .topLeading, endPoint: .bottomTrailing)

            ScrollViewIfNeeded {
                VStack {
                    PlusLabel(L10n.plusMarketingTitle, for: .title2)

                    HStack(spacing: 0) {
                        ZStack {
                            Text("Yearly")
                                .font(style: .subheadline, weight: .medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .background(.white)
                        .cornerRadius(24)
                        .padding(.all, 4)

                        ZStack {
                            Text("Monthly")
                                .font(style: .subheadline, weight: .medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .cornerRadius(24)
                        .padding(.all, 4)
                    }
                    .background(.white.opacity(0.16))
                    .cornerRadius(24)

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

                            HStack() {
                                Text("$39.99")
                                    .font(style: .largeTitle, weight: .bold)
                                Text("/year")
                                    .font(style: .headline, weight: .bold)
                                    .opacity(0.6)
                                    .padding(.top, 6)
                            }
                            Text("Take your podcasting experience to the next level with exclusive access to features and customization options.")
                                .font(style: .caption2, weight: .semibold)
                                .opacity(0.64)

                            HStack(spacing: 16) {
                                Image("plus-feature-desktop")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.black)
                                    .frame(width: 16, height: 16)
                                Text("Desktop apps")
                                    .font(size: 14, style: .subheadline, weight: .medium)
                            }
                            HStack(spacing: 16) {
                                Image("plus-feature-folders")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.black)
                                    .frame(width: 16, height: 16)
                                Text("Folders")
                                    .font(size: 14, style: .subheadline, weight: .medium)
                            }
                            HStack(spacing: 16) {
                                Image("plus-feature-cloud")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.black)
                                    .frame(width: 16, height: 16)
                                Text("10GB cloud storage")
                                    .font(size: 14, style: .subheadline, weight: .medium)
                            }
                            HStack(spacing: 16) {
                                Image("plus-feature-watch")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.black)
                                    .frame(width: 16, height: 16)
                                Text("Apple Watch playback")
                                    .font(size: 14, style: .subheadline, weight: .medium)
                            }
                            HStack(spacing: 16) {
                                Image("plus-feature-extra")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.black)
                                    .frame(width: 16, height: 16)
                                Text("Extra themes & icons")
                                    .font(size: 14, style: .subheadline, weight: .medium)
                            }
                            HStack(alignment: .top, spacing: 16) {
                                Image("plus-feature-love")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.black)
                                    .frame(width: 16, height: 16)
                                Text("The undying gratitude of everyone here at Pocket Casts")
                                    .font(size: 14, style: .subheadline, weight: .medium)
                            }

                            Button("Subscribe to Plus") {

                            }
                            .buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, background: Color(hex: "FFD846")))
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
