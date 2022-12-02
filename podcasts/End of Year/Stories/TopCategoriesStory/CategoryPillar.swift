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
                        .fill(LinearGradient(gradient: Gradient(colors: [color, .black.opacity(0)]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 90, height: height)
                        .padding(.top, 26)

                    ZStack {
                        Image("square_perspective")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 90, height: 52)
                            .foregroundColor(color)

                        let whiteContrast = color.contrast(with: .white)
                        let textColor = whiteContrast < 2 ? UIColor.black.color : UIColor.white.color

                        let values: [CGFloat] = [1, 0, 0.50, 1, 0, 0]
                        Text(text)
                            .font(.system(size: 18, weight: .heavy))
                            .multilineTextAlignment(.center)
                            .foregroundColor(textColor)
                            .padding(.leading, -8)
                        .transformEffect(CGAffineTransform(
                            a: values[0], b: values[1],
                            c: values[2], d: values[3],
                            tx: 0, ty: 0
                        ))
                        .rotationEffect(.init(degrees: -30))
                    }
                }
            }

            Spacer()
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
