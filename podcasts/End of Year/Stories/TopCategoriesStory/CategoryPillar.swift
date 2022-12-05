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
                    .frame(width: Constants.width)
                    .fixedSize()
                    .padding(.bottom, 2)
                StoryLabel(subtitle, for: .pillarSubtitle)
                    .frame(width: Constants.width)
                    .fixedSize()
                    .opacity(0.8)
                    .padding(.bottom, 20)

                ZStack(alignment: .top) {
                    Group {
                        // Main pillar
                        Rectangle()
                            .fill(LinearGradient(gradient: Gradient(colors: [color, color.opacity(0)]), startPoint: .top, endPoint: .bottom))
                            .frame(width: 103, height: height)
                            .padding(.top, 37)

                        // Left Shadow
                        Rectangle()
                            .fill(LinearGradient(gradient: Gradient(colors: [.black, .black.opacity(0)]), startPoint: .top, endPoint: .bottom))
                            .frame(width: 73.5, height: height)
                            .padding(.top, 40)
                            .rotation3DEffect(
                                Angle(degrees: 45),
                                axis: (x: 0, y: -1, z: 0),
                                anchor: .center,
                                anchorZ: 0,
                                perspective: 0
                            )
                            .rotation3DEffect(
                                Angle(degrees: 10),
                                axis: (x: 0, y: 1, z: 0),
                                anchor: .center,
                                anchorZ: 0,
                                perspective: 1
                            )
                            .opacity(0.3)
                            .offset(x: -25.5)

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
                    .frame(width: Constants.width)
                }
            }

            Spacer()
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private enum Constants {
        static let width = 90.0
    }
}
