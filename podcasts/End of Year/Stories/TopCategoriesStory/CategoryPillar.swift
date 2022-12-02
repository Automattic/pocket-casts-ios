import SwiftUI

struct CategoryPillar: View {
    let color: Color
    let text: String
    let title: String
    let subtitle: String
    let height: CGFloat

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                StoryLabel(title, for: .pillarTitle)
                    .frame(width: 90)
                    .fixedSize()
                    .padding(.bottom, 2)
                StoryLabel(subtitle, for: .pillarSubtitle)
                    .frame(width: 90)
                    .fixedSize()
                    .opacity(0.8)
                    .padding(.bottom, 20)

                ZStack(alignment: .top) {
                        Rectangle()
                            .fill(LinearGradient(gradient: Gradient(colors: [color, color.opacity(0)]), startPoint: .top, endPoint: .bottom))
                            .frame(width: 103, height: height)
                            .padding(.top, 37)

                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(width: 75.0, height: 75.0)

                            let whiteContrast = color.contrast(with: .white)
                            let textColor = whiteContrast < 2 ? Color.black : Color.white

                            Text(text)
                                .font(.system(size: 24, weight: .heavy))
                                .multilineTextAlignment(.center)
                                .foregroundColor(textColor)
                        }.modifier(PodcastCoverPerspective(scaleAnchor: .center))
                    }
                }
            }

            Spacer()
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
